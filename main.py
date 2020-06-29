from tkinter import *


def draw_mandelbrot_set(w, mi, ss):
    canvas = Canvas(width=ss[0], height=ss[1], bg='black')
    canvas.place(x=0, y=0)
    for i in range(1, ss[0] + 1):
        for j in range(1, ss[1] + 1):
            c = complex(w[0][0] + i * (w[1][0] - w[0][0]) / ss[0], w[1][1] - j * (w[1][1] - w[0][1]) / ss[1])
            z0 = 0
            for k in range(0, mi):
                z0 = z0 * z0 + c
                if abs(z0) > 2:
                    color = '#%02x%02x%02x' % (int(255*k/mi), int(255*k/mi), 255)
                    canvas.create_rectangle(i, j, i, j, fill=color, outline=color)
                    break
    return canvas


if __name__ == "__main__":
    W = [[-1.5, -1.1], [0.5, 1.1]]
    max_iter = 100
    screen_size = [700, 700]
    gui = Tk()
    gui.geometry("{}x{}".format(screen_size[0], screen_size[1]))
    draw_mandelbrot_set(W, max_iter, screen_size)
    mainloop()
