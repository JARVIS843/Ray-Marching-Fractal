#import pygame and essential libraries
import pygame , sys
from pygame.locals import *

#import OpenGL
from OpenGL.GL import *
from OpenGL.GLU import *


#Fields & Data
Display_Size = (1280,1024)

clock = pygame.time.Clock()

FPSLim = 300

#Main execution
if __name__ == "__main__":
    pygame.init()
    pygame.display.set_mode(Display_Size, DOUBLEBUF|OPENGL)
    gluPerspective(110 , Display_Size[0]/Display_Size[1] , 0.01 , 50)
    
    
    while True:                                                 #Start of update func
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                sys.exit(0)
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    sys.exit(0)
                    
        glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT)        #Clear Two buffers before entering next frame to avoid repeatitive rendering
        
        #Calculations & Methods are implemented before flip()
        
        
        
        
        
        pygame.display.flip();                                  #update frame
        clock.tick(FPSLim)
        print(clock.get_fps())
        