#import pygame and essential libraries
import pygame , sys , math
from pygame.locals import *


#import OpenGL
from OpenGL.GL import *
from OpenGL.GLU import *


#Fields & Data
Display_Size = (1280,1024)

clock = pygame.time.Clock()

FPSLim = 300


vertices= (
    (1, -1, -1),
    (1, 1, -1),
    (-1, 1, -1),
    (-1, -1, -1),
    (1, -1, 1),
    (1, 1, 1),
    (-1, -1, 1),
    (-1, 1, 1)
    )

edges = (
    (0,1),
    (0,3),
    (0,4),
    (2,1),
    (2,3),
    (2,7),
    (6,3),
    (6,4),
    (6,7),
    (5,1),
    (5,4),
    (5,7)
    )

def Cube():
    glBegin(GL_LINES)
    for edge in edges:
        for vertex in edge:
            glVertex3fv(vertices[vertex])
    glEnd()

#Main execution
if __name__ == "__main__":




    pygame.init()
    
    scree = pygame.display.set_mode(Display_Size, DOUBLEBUF|OPENGL)
    
    glMatrixMode(GL_PROJECTION)
    gluPerspective(110 , Display_Size[0]/Display_Size[1] , 0.01 , 50)
    glMatrixMode(GL_MODELVIEW)
    gluLookAt(0, -8, 0, 0, 0, 0, 0, 0, 1)
    viewMatrix = glGetFloatv(GL_MODELVIEW_MATRIX)
    glLoadIdentity()

    glTranslatef(0,0,-10)
    
    
    # init mouse movement and center mouse on screen
    displayCenter = [scree.get_size()[i] // 2 for i in range(2)]
    mouseMove = [0, 0]
    pygame.mouse.set_pos(displayCenter)

    up_down_angle = 0.0

    while True:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                sys.exit(0)
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    sys.exit(0)
            if event.type == pygame.MOUSEMOTION:
                mouseMove = [event.pos[i] - displayCenter[i] for i in range(2)]
            pygame.mouse.set_pos(displayCenter)    

        # get keys
        keypress = pygame.key.get_pressed()
        #mouseMove = pygame.mouse.get_rel()
        # init model view matrix
        glLoadIdentity()
        # apply the look up and down
        up_down_angle += mouseMove[1]*0.1
        glRotatef(up_down_angle, 1.0, 0.0, 0.0)
        # init the view matrix
        glPushMatrix()
        glLoadIdentity()
        # apply the movment 
        if keypress[pygame.K_w]:
            glTranslatef(0,0,0.1)
            
        if keypress[pygame.K_s]:
            glTranslatef(0,0,-0.1)
            
        if keypress[pygame.K_d]:
            glTranslatef(-0.1,0,0)
            
        if keypress[pygame.K_a]:
            glTranslatef(0.1,0,0)
            
        # apply the left and right rotation
        glRotatef(mouseMove[0]*0.1, 0.0, 1.0, 0.0)
        
        
        # multiply the current matrix by the get the new view matrix and store the final vie matrix 
        glMultMatrixf(viewMatrix)
        viewMatrix = glGetFloatv(GL_MODELVIEW_MATRIX)
        
        
        # apply view matrix
        glPopMatrix()
        glMultMatrixf(viewMatrix)
        
        
        glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT)
        
        Cube()
        
        pygame.display.flip();                                  #update frame
        
        clock.tick(FPSLim)                                      #Set Limit for FPS
        
        print(clock.get_fps())
    