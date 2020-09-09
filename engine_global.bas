'#################################################################
'--------------------+ QB64 OpenGL Engine +-----------------------
'                          [ALPHA] 
'                     By Ashish Kushwaha                          
'GitHub: https://github.com/AshishKindom/QB64-OpenGL-Engine
'LICENSE: GPL v3.0
'-----------------------------------------------------------------
'#################################################################
RANDOMIZE TIMER
'#################################################################
'------------------- CONSTANT DECLARATIONS -----------------------
'#################################################################
CONST ENGINE_GEOMETRY_POINT = 1
CONST ENGINE_GEOMETRY_LINE = 2
CONST ENGINE_GEOMETRY_TRIANGLE = 3
CONST ENGINE_GEOMETRY_QUAD = 4

CONST ENGINE_2D = 11
CONST ENGINE_3D = 12

CONST ENGINE_COORD_OPENGL = 15
CONST ENGINE_COORD_DEFAULT = 16

CONST ENGINE_LIBRARY_VERSION = 1.0


'#################################################################
'---------------------- UDTs DECLARATIONS ------------------------
'#################################################################

TYPE engine_internal_type_vec3 'type for vector having 3 component
    x as single
    y as single
    z as single
END TYPE

TYPE engine_internal_type_vertex 'vertex type which will be used rendering. (13 bytes)
    v as engine_internal_type_vec3 'position (12 bytes)
    used as _byte 'if used its value is -1 else 0 (1 byte)
end type

type engine_internal_type_mesh
    geometry_type as _byte 'describe the fundamental geometry which will be used for rendering whole mess. Can be ENGINE_GEOMETRY_POINT, ENGINE_GEOMETRY_TRIANGLE, ENGINE_GEOMETRY_LINE, etc
    used as _byte 'if used its value is -1 else 0
    mesh_v_index as _unsigned long 'the main mesh vertex data reference index in engine_internal_vertex_list array
    mesh_total_v as _unsigned long 'total number of vertices for the mesh
    id as string*32 'unique ID for each name.
end type


'#################################################################
'------------------- VARIABLES DECLARATIONS ----------------------
'#################################################################

redim shared engine_internal_vertex_list(3) as engine_internal_type_vertex
redim shared engine_internal_mesh_list(0) as engine_internal_type_mesh

dim shared engine_enable_drawing as _byte, engine_coord_system as _byte, engine_texture as _byte
dim shared engine_canvas as _unsigned long

engine_enable_drawing = 0
engine_coord_system = ENGINE_COORD_DEFAULT
engine_texture = 0
engine_canvas = _newimage(640, 480, 32)
_GLRENDER _ONLY
screen engine_canvas