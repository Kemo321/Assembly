#include <stdio.h>
#include <stdlib.h>
#include <SDL.h>
#include "Julia.h"


typedef enum 
{
    false = 0,
    true = 1
} 
bool;


int main(int argc, char* argv[]) 
{
    int colors[32] = {
        0x000000FF, // black
        0xFF00FF00, // Green
        0xFF0000FF, // Blue
        0xFFFFFF00, // Yellow

        0xFFFF00FF, // Magenta
        0xFF00FFFF, // Cyan
        0xFFFFA500, // Orange
        0xFF800080, // Purple

        0xFF808080, // Gray
        0xFFA52A2A, // Brown
        0xFF8B0000, // Dark Red
        0xFF006400, // Dark Green

        0xFF00008B, // Dark Blue
        0xFF2E8B57, // Sea Green
        0xFF4682B4, // Steel Blue
        0xFFD2691E, // Chocolate

        0xFFFFD700, // Gold
        0xFF7FFF00, // Chartreuse
        0xFFADFF2F, // Green Yellow
        0xFF32CD32, // Lime Green

        0xFF87CEEB, // Sky Blue
        0xFF00FA9A, // Medium Spring Green
        0xFF8FBC8F, // Dark Sea Green
        0xFF6495ED, // Cornflower Blue

        0xFF00BFFF, // Deep Sky Blue
        0xFF1E90FF, // Dodger Blue
        0xFF20B2AA, // Light Sea Green
        0xFF7FFFD4, // Aquamarine

        0xFF40E0D0, // Turquoise
        0xFF00CED1, // Dark Turquoise
        0xFF00FFFF, // Aqua
        0xFFADD8E6 // Light Blue
    };

    // Parameter initialization
    int width;
    int height;
    if (argc != 3)
    {
        width = 800;
        height = 800;
    }
    else
    {
        width = atoi(argv[1]);
        height = atoi(argv[2]);
    }
    double treshold = 4;
    double c_real = -0.75;
    double c_imag = 0.15;
    double centerX = height / 2;
    double centerY = width / 2;
    double zoom = 1.0;
    bool colored = false;

    if (argc == 3)
        colored = false; 
    else
        colored = true;

    // Initialize SDL
    if (SDL_Init(SDL_INIT_VIDEO) < 0) 
    {
        // SDL initialization failed
        printf("Could not initialize SDL: %s\n", SDL_GetError());
        return 1;
    }

    // Create a window and renderer
    SDL_Window* window = SDL_CreateWindow("Julia Fractal", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, width, height, SDL_WINDOW_SHOWN);
    if (window == NULL) 
    {
        // Window creation failed
        printf("Could not create window: %s\n", SDL_GetError());
        SDL_Quit();
        return 1;
    }

    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    if (renderer == NULL)
    {
        // Renderer creation failed
        printf("Could not create renderer: %s\n", SDL_GetError());
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    // Create a texture
    SDL_Texture* texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, width, height);
    if (texture == NULL) 
    {
        // Texture creation failed
        printf("Could not create texture: %s\n", SDL_GetError());
        SDL_DestroyRenderer(renderer);
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    // Lock the texture to access its pixel data
    void* pixels;
    int pitch;
    SDL_LockTexture(texture, NULL, (void**)&pixels, &pitch);


    // Generate base Fractal
    GenerateFractal((uint8_t*)pixels, width, height, treshold, c_real, c_imag, width/2.0, height/2.0, 1.0, colors, colored);



    // Unlock the texture
    SDL_UnlockTexture(texture);

    // Main loop flag
    bool quit = false;

    // Event handler
    SDL_Event e;

    // Flag to check if new fractal should be generated
    bool modified = false;

    // Variables for dragging
    bool isDragging = false;
    int dragStartX = 0, dragStartY = 0;
    double dragStartCenterReal = 0, dragStartCenterImag = 0;


    // Main loop
    while (!quit) 
    {
        // Handle events on queue
        while (SDL_PollEvent(&e) != 0) 
        {
            // User requests quit
            if (e.type == SDL_QUIT) 
            {
                quit = true;
            }

            // Check for other events
            else if (e.type == SDL_MOUSEWHEEL) 
            {
                double fractalCenterX = width / 2.0;
                double fractalCenterY = height / 2.0;
                if (e.wheel.y > 0) 
                {
                    // Zoom in
                    double zoomFactor = 1.25;
                    zoom *= zoomFactor;
                    centerX = (centerX - fractalCenterX) * zoomFactor + fractalCenterX;
                    centerY = (centerY - fractalCenterY) * zoomFactor + fractalCenterY;
                    modified = true;
                }
                else if (e.wheel.y < 0) 
                {
                    // Zoom out
                    double zoomFactor = 0.8;
                    zoom *= zoomFactor;
                    centerX = (centerX - fractalCenterX) * zoomFactor + fractalCenterX;
                    centerY = (centerY - fractalCenterY) * zoomFactor + fractalCenterY;
                    modified = true;
                }
            }
            else if (e.type == SDL_KEYDOWN) 
            {
                switch (e.key.keysym.sym) 
                {
                    case SDLK_c:
                        colored = !colored;
                        modified = true;
                        break;
                    case SDLK_UP:
                        c_real += 0.05;
                        modified = true;
                        break;
                    case SDLK_DOWN:
                        c_real -= 0.05;
                        modified = true;
                        break;
                    case SDLK_LEFT:
                        c_imag -= 0.05;
                        modified = true;
                        break;
                    case SDLK_RIGHT:
                        c_imag += 0.05;
                        modified = true;
                        break;
                    case SDLK_DELETE:
                        // Default parameters
                        c_real = -0.75;
                        c_imag = 0.15;
                        centerX = height / 2;
                        centerY = width / 2;
                        zoom = 1.0;
                        modified = true;
                        break;
                    default:
                        break;
                }
            }
            else if (e.type == SDL_MOUSEBUTTONDOWN && e.button.button == SDL_BUTTON_LEFT)
            {
                isDragging = true;
                SDL_GetMouseState(&dragStartX, &dragStartY);
                dragStartCenterReal = centerX;
                dragStartCenterImag = centerY;
            }
            else if (e.type == SDL_MOUSEMOTION && isDragging)
            {
                // Convert screen coordinates to fractal coordinates
                double fractalMouseX = (e.motion.x - width / 2) + centerX;
                double fractalMouseY = (e.motion.y - height / 2) + centerY;

                // Calculate deltas in fractal coordinates
                double deltaX = fractalMouseX - (dragStartX - width / 2) - dragStartCenterReal;
                double deltaY = fractalMouseY - (dragStartY - height / 2) - dragStartCenterImag;

                // Update center position
                centerX -= deltaX;
                centerY -= deltaY;
            }
            else if (e.type == SDL_MOUSEBUTTONUP)
            {
                if (e.button.button == SDL_BUTTON_LEFT) 
                    {
                        isDragging = false;

                        // Re-generate Fractal with new center position
                        SDL_LockTexture(texture, NULL, &pixels, &pitch);
                        GenerateFractal((uint8_t*)pixels, width, height, treshold, c_real, c_imag, centerX, centerY, zoom, colors, colored);
                        SDL_UnlockTexture(texture);
                    }
            }
        }

        if (modified)
        {
            // Lock texture
            SDL_LockTexture(texture, NULL, (void**)&pixels, &pitch);
            // Generate new Fractal
            GenerateFractal((uint8_t*)pixels, width, height, treshold, c_real, c_imag, centerX, centerY, zoom, colors, colored);
            // Unlock the texture
            SDL_UnlockTexture(texture);
            modified = false;
        }

        // Clear the screen
        SDL_RenderClear(renderer);

        // Copy the texture to the renderer
        SDL_RenderCopy(renderer, texture, NULL, NULL);

        // Update the screen
        SDL_RenderPresent(renderer);
    }

    // Destroy window, renderer, and texture
    SDL_DestroyTexture(texture);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);

    // Quit SDL
    SDL_Quit();

    return 0;
}