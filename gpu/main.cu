#include <SDL2/SDL.h>
#include <iostream>
#include <string.h>
#include <math.h>

// Screen size
#define SCREEN_HEIGHT (700)
#define SCREEN_WIDTH  (700)

// Max number of iteration for the check of convergence
#define MAX_ITERATION (100)

// Window of the complex plane to display
#define W1X (-1.5)
#define W1Y (-1.1)
#define W2X (0.5)
#define W2Y (1.1)

// Size of the buffer containing the image of the Mandelbrot set
#define BUFFER_SIZE  (SCREEN_HEIGHT * SCREEN_WIDTH * 4)
#define CBUFFER_SIZE (BUFFER_SIZE * sizeof(char))

typedef struct
{
    float x;
    float y;
} complex;

__device__ float modulus(complex z) {
    return sqrt(pow(z.x, 2) + pow(z.y, 2));
}

__device__ complex add(complex z0, complex z1) {
    complex res = {0};

    res.x = z0.x + z1.x;
    res.y = z0.y + z1.y;
    return res;
}

__device__ complex mul(complex z0, complex z1) {
    complex res = {0};

    res.x = z0.x * z1.x - z0.y * z1.y;
    res.y = z0.x * z1.y + z0.y * z1.x;
    return res;
}

__global__ void mandelbrot_set(char *data)
{
    int idx = threadIdx.x + blockIdx.x * blockDim.x;
    int idy = threadIdx.y + blockIdx.y * blockDim.y;
    int id  = 4 * (idx + idy * SCREEN_WIDTH);

    if (idx >= SCREEN_WIDTH || idy >= SCREEN_HEIGHT) {
        return;
    }
    complex z0 = {0};
    complex c = {0};
    c.x = W1X + idx * (W2X - W1X) / SCREEN_WIDTH;
    c.y = W2Y - idy * (W2Y - W1Y) / SCREEN_HEIGHT;
    for (int i = 0; i < MAX_ITERATION; ++i) {
        z0 = add(mul(z0, z0), c);
        if (modulus(z0) > 2) {
            data[id]     = 255;
            data[id + 1] = 255;
            data[id + 2] = 255 * i / MAX_ITERATION;
            data[id + 3] = 255 * i / MAX_ITERATION;
            return;
        }
    }

}

SDL_Surface *compute_mandelbrot_set() {

    // Check if at least one CUDA device is available
    int devCount;
    cudaGetDeviceCount(&devCount);
    cudaError_t err = cudaGetDeviceCount(&devCount);
    if (err != cudaSuccess) {
        printf("%s\n", cudaGetErrorString(err));
        exit(-1);
    }
    if (devCount <= 0) {
        printf("No CUDA gpu available on this system.\n");
        exit(-1);
    }

    // Allocate the data and run the kernel
    char *data;
    cudaMallocManaged(&data, CBUFFER_SIZE);
    dim3 block(20,20, 1);
    dim3 grid(35, 35, 1);
    mandelbrot_set<<<grid,block>>>(data);
    cudaDeviceSynchronize();

    void *hostData = malloc(CBUFFER_SIZE);
    cudaMemcpy(hostData, data, CBUFFER_SIZE, cudaMemcpyDeviceToHost);

    // Copy result in the SDL surface
    SDL_Surface *image = SDL_CreateRGBSurfaceWithFormatFrom(hostData,
                                                            SCREEN_WIDTH,
                                                            SCREEN_HEIGHT,
                                                            32,
                                                            SCREEN_WIDTH * 4,
                                                            SDL_PIXELFORMAT_RGBA8888);
    cudaFree(data);
    return image;
}

int main() {

    if(SDL_Init(SDL_INIT_VIDEO) < 0)
    {
        std::cout << "Failed to initialize the SDL2 library\n";
        return -1;
    }

    SDL_Window *window = SDL_CreateWindow("Mandelbrot set",
                                          SDL_WINDOWPOS_CENTERED,
                                          SDL_WINDOWPOS_CENTERED,
                                          SCREEN_HEIGHT,
                                          SCREEN_WIDTH,
                                          0);

    if(!window)
    {
        std::cout << "Failed to create window\n";
        return -1;
    }

    SDL_Surface *window_surface = SDL_GetWindowSurface(window);

    if(!window_surface)
    {
        std::cout << "Failed to get the surface from the window\n";
        return -1;
    }

    SDL_Surface *image = compute_mandelbrot_set();
    SDL_BlitSurface(image, NULL, window_surface, NULL);
    SDL_UpdateWindowSurface(window);

    bool keep_window_open = true;
    while(keep_window_open)
    {
        SDL_Event e;
        while(SDL_PollEvent(&e) > 0)
        {
            switch(e.type)
            {
                case SDL_QUIT:
                    keep_window_open = false;
                    break;
            }
        }
    }
}
