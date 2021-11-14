#imports 
from ctypes import *
from OpenGL.GL import *
from OpenGL.GLU import *
import os

class Shader:  
    
    def __init__(self, shader_used):
        self.fragtype = shader_used

    def DecodeShaders(self):
        shade = {
        "Soft Shadow": 'SSShader.glsl',
        "Mandelbulb" : 'Mandelbulb.glsl',
        "Sierpinski Tetrahedron" : 'ST.glsl'
                    }
        
        
        
        #Obtain directory of vertex and fragment shader
        vertex_dir = os.path.join(os.path.dirname(__file__),'VertShader.glsl')
        fragment_dir = os.path.join(os.path.dirname(__file__),shade[self.fragtype])
        #Read the shader and convert to string
        vertshader = open(vertex_dir).read()
        fragshader = open(fragment_dir).read()

        program = self.CompileProgram(vertshader,fragshader)

        return program

    

    def CompileShader(self , source,shader_type):
        #Create and Compile shaders
        shader = glCreateShader(shader_type) 
        glShaderSource(shader, source)
        glCompileShader(shader)

        status = c_int()
        glGetShaderiv(shader, GL_COMPILE_STATUS, byref(status))

        if not status.value:
            self.print_log(shader)
            glDeleteShader(shader)	
            raise ValueError('Shader compilation failed')
		
        return shader



    def CompileProgram(self ,vertex_source,fragment_source):
        vertex_shader = None
        fragment_shader = None
        #Create program
        program = glCreateProgram()

        if vertex_source:		
            print("Compiling Vertex Shader...")	
            #Create and attach vertex shader to program	
            vertex_shader = self.CompileShader(vertex_source, GL_VERTEX_SHADER)    
            glAttachShader(program, vertex_shader)
		
        if fragment_source:		
            print("Compiling Fragment Shader...")		
            #Create and attach fragment shader to program
            fragment_shader = self.CompileShader(fragment_source, GL_FRAGMENT_SHADER)			
            glAttachShader(program, fragment_shader)

        #Binding vertex attribute position to defaut location 0
        glBindAttribLocation(program, 0, "pos")               #TODO add and link VertexArray and Pointer to location 0
		
        #link and prepare program for use
        glLinkProgram(program)		
        if vertex_shader:			
            glDeleteShader(vertex_shader)		
        if fragment_shader:			
            glDeleteShader(fragment_shader)

        return program
    
    
    def print_log(self,shader):
        length = c_int()
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, byref(length))
        
        if length.value > 0:
            log = create_string_buffer(length.value)
            print(glGetShaderInfoLog(shader))
    	





    
        
