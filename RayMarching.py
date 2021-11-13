#import pygame and essential libraries
import pygame , sys , math
from pygame.locals import *
import numpy as np

#import from local files
from utilities.Shaders import Shader

#import OpenGL
from OpenGL.GL import *
from OpenGL.GLU import *


#Fields & Data
Display_Size = (1280,800)

clock = pygame.time.Clock()

FPSLim = 300

Velocity = 0.01;

SpeedUpFactor = 10;

InitPos = [0,0,10]              #Initial Position: away from Z axis

Transform = np.identity(4)      #Initialize transform matrix with identity

#Temp Tests
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
    
#Rotation in X axis, more info on https://stackabuse.com/understanding-opengl-through-python/
def RotateX(theta):
    cosine = math.cos(theta)
    sine = math.sin(theta)
    
    MatrixF = np.array(
                [[1,0,0],
                [0,cosine,-sine],
                [0,sine,cosine]],dtype = np.float32
                        )
    return MatrixF

#Rotation in Y axis
def RotateY(theta):
    cosine = math.cos(theta)
    sine = math.sin(theta)
    
    MatrixF = np.array(
                [[cosine,0,sine],
                [0,1,0],
                [-sine,0,cosine]], dtype = np.float32
                    )

#Main execution
if __name__ == "__main__":




    pygame.init()
    
    pygame.display.set_mode(Display_Size, DOUBLEBUF|OPENGL)
    pygame.mouse.set_visible(False);
    
    #Setting up the scene
    #glMatrixMode(GL_PROJECTION)
    #gluPerspective(110 , Display_Size[0]/Display_Size[1] , 0.01 , 50)
    #glMatrixMode(GL_MODELVIEW)
    #gluLookAt(0, -8, 0, 0, 0, 0, 0, 0, 1)
    #viewMatrix = glGetFloatv(GL_MODELVIEW_MATRIX)
    #glLoadIdentity()
    #glTranslatef(0,0,-10)

    # init mouse movement and center mouse on screen
    displayCenter = [Display_Size[0]/2 , Display_Size[1]/2]
    mouseMove = [0, 0]
    pygame.mouse.set_pos(displayCenter)

    #Setting Up shaders
    shader = Shader()
    program = shader.DecodeShaders()
    glUseProgram(program)
    
    #Obtain storage locations of shader variables
    ResolutionLoc = glGetUniformLocation(program, "iResolution")



    #Dispatch data to Fragment Shader through obtained locations
    glUniform2fv(ResolutionLoc, 1, Display_Size)



    #Enable Vertex Array and Pointer
    fullscreen_quad = np.array([-1.0, -1.0, 0.0, 1.0, -1.0, 0.0, -1.0, 1.0, 0.0, 1.0, 1.0, 0.0], dtype=np.float32)
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, fullscreen_quad)
    glEnableVertexAttribArray(0)

    #Load Transfrom Matrix with initial position
    Transform[3 , :3] = InitPos
    
    print(Transform)
    
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

        

        
        glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT)
        
        glDrawArrays(GL_TRIANGLE_STRIP,0,4)
        Cube()

        
        pygame.display.flip()                                 #update frame
        
        clock.tick(FPSLim)                                      #Set Limit for FPS
        
        #print(clock.get_fps())
    