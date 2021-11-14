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

v_lim = 4

v = np.zeros((3,), dtype = np.float32)                       #Velocity

SpeedUpFactor = 20

InitPos = [5.0 ,1.0, 5.0]              #Initial Position: away from Z axis

Transform = np.identity(4)      #Initialize transform matrix with identity

dt = 0.001              #Delta Time

DPI_Multiplier = 1.6         #Factor of DPI

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
    return MatrixF
    
#Normalize a given vector
def normalize(lst):
    if(lst.__contains__(0)): return 0
    else:
        norm = [float(i)/max(lst) for i in lst]
        return norm

#Main execution
if __name__ == "__main__":

    pygame.init()
    pygame.display.set_caption('3D Fractal Visualizer with Buffs')
    pygame.display.set_mode(Display_Size, DOUBLEBUF|OPENGL)
    pygame.mouse.set_visible(False)

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
    TransformLoc = glGetUniformLocation(program, "iMat")
    


    #Dispatch data to Fragment Shader through obtained locations
    glUniform2fv(ResolutionLoc, 1, Display_Size)
    
    
    #Enable Vertex Array and Pointer
    fullscreen_quad = np.array([-1.0, -1.0, 0.0, 1.0, -1.0, 0.0, -1.0, 1.0, 0.0, 1.0, 1.0, 0.0], dtype=np.float32)
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, fullscreen_quad)
    glEnableVertexAttribArray(0)

    #Load Transfrom Matrix with initial position
    Transform[3 , :3] = InitPos
    
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

        
        
        #Advanced Controls
        Transform[3,:3] += v * dt
        #WASD Controls
        KeyPressed = pygame.key.get_pressed()
        vec = np.zeros((3,), dtype=np.float32)
        
        
        if pygame.key.get_focused():                                    #if Key is pressed
            x = -mouseMove[0] * DPI_Multiplier * dt
            y = -mouseMove[1] * DPI_Multiplier * dt

            rx = RotateY(x)
            ry = RotateX(y)
            Transform[:3,:3] = np.dot(ry, np.dot(rx, Transform[:3,:3]))
            
            if KeyPressed[pygame.K_w]:
                vec[2] += 2/FPSLim
            if KeyPressed[pygame.K_s]:
                vec[2] -= 2/FPSLim
            if KeyPressed[pygame.K_a]:
                vec[0] -= 2/FPSLim
            if KeyPressed[pygame.K_d]:
                vec[0] += 2/FPSLim
            if KeyPressed[pygame.K_q]:
                vec[1] += 2/FPSLim
            if KeyPressed[pygame.K_e]:
                vec[1] -= 2/FPSLim
            if KeyPressed[pygame.K_LSHIFT]:
                v *= SpeedUpFactor
            
            #Apply Calculations to Transform matrix
            v += np.dot(Transform[:3,:3].T, vec)
            v_ratio = min(v_lim , 1e20) / (np.linalg.norm(v) + 1e-12)
            if v_ratio < 1.0 : 
                v *= v_ratio
        #If no input is detected               
        if np.dot(vec,vec) == 0.0 :
            v *= 0.5
            
            
        
        glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT)
        glUniformMatrix4fv(TransformLoc,1 , False, Transform)
        glDrawArrays(GL_TRIANGLE_STRIP,0,4)
        
        pygame.display.flip()                                 #update frame
        
        clock.tick(FPSLim)                                      #Set Limit for FPS
        
        print(clock.get_fps())
    