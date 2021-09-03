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
CONST ENG_GEOMETRY_POINT = 1 'value is set in such a way that it equal to no. vertice(s) it has (eg - point as 1 vertex, triangle has 3 vertices, etc)
CONST ENG_GEOMETRY_LINE = 2
CONST ENG_GEOMETRY_TRIANGLE = 3
CONST ENG_GEOMETRY_QUAD = 4
CONST ENG_GEOMETRY_ELLIPSE = 5

CONST ENG_2D = 11
CONST ENG_3D = 12

CONST ENG_COORD_OPENGL = 15
CONST ENG_COORD_DEFAULT = 16

'this is how a single vertex is stored in memory (each element is of SINGLE data type. Thus, a single vertex uses 24 bytes of memory)
' x_position y_position z_position color_red color_green color_blue
CONST ENG_VERT_MEMORY = 24

CONST ENG_LIBRARY_VERSION = 1.0


'#################################################################
'---------------------- UDTs DECLARATIONS ------------------------
'#################################################################

TYPE ENG_internal_type_vec3 'type for vector having 3 component
    x as single
    y as single
    z as single
END TYPE


TYPE ENG_internal_type_vertex 'vertex type which will be used rendering. (13 bytes)
    v as ENG_internal_type_vec3 'position (12 bytes)
    used as _byte 'if used its value is -1 else 0 (1 byte)
end type

type ENG_type_mesh
    geometry_type as _byte 'describe the fundamental geometry which will be used for rendering whole mess. Can be ENG_GEOMETRY_POINT, ENG_GEOMETRY_TRIANGLE, ENG_GEOMETRY_LINE, etc
    used as _byte 'if used its value is 1 else 0
    fill as _byte 'if true, shape will be filled (it gets ignored for line & points)
    fill_color as ENG_internal_type_vec3 'the color which will be used to fill the shape
    border as _byte 'if true, shape will have border
    border_color as ENG_internal_type_vec3 'the color which will be used to draw the border
    border_thickness as _byte'the value of border thickness
    hidden as _byte 'if true, the object will not be rendered
    mesh_total_v as _unsigned long 'total number of vertices for the mesh
    mesh_data as _mem 'used to store all data, like color, vertices, etc
end type

'#################################################################
'------------------- VARIABLES DECLARATIONS ----------------------
'#################################################################

'below arrays will be used for storing normalized ellipse vertices
dim shared ENG_internal_ev1(1 to 32) as ENG_internal_type_vec3
dim shared ENG_internal_ev2(1 to 100) as ENG_internal_type_vec3
dim shared ENG_internal_ev3(1 to 500) as ENG_internal_type_vec3

dim shared ENG_enable_drawing as _byte, ENG_coord_system as _byte, ENG_texture as _byte
dim shared ENG_enable_fill as _byte, ENG_enable_border as _byte, ENG_border_thickness as _byte
dim shared ENG_canvas as long, ENG_canvas2 as long
dim shared ENG_clear_color as ENG_internal_type_vec3
dim shared ENG_fill_color as ENG_internal_type_vec3, ENG_border_color as ENG_internal_type_vec3

'#################################################################
'---------------------- CONFIGURATIONS ---------------------------
'#################################################################
ENG_enable_drawing = 0
ENG_coord_system = ENG_COORD_DEFAULT
ENG_texture = 0
ENG_enable_fill = 1
ENG_enable_border = 1
ENG_border_thickness = 2

ENG_canvas = _newimage(640, 480, 32)
ENG_canvas2 = _copyimage(ENG_canvas)
$if ENG_SOFTWARE_MODE then
    redim shared ENG_pixel_data(1 to _width(ENG_canvas) * _height(ENG_canvas) * 4) as _unsigned _byte 'ENG_pixel_data will only store pixel data if software mode is enabled.
    'in software rendering mode, each call to ENG.draw will be stored in a string with essential mesh object data
    'it is used by SUB _GL to draw all the primitives (if any) and then capture that screen and write all pixel data
    'into ENG_canvas
    dim shared ENG_draw_calls as STRING, ENG_mem as _mem, ENG_offset_size as _byte
    dim ENG_temp_o as _offset
    ENG_temp_o = 555 'just to store what is the size of offset in the system
    ENG_offset_size = len(ENG_temp_o)
    ENG_mem = _memimage(ENG_canvas2)
$end if

ENG_clear_color.x = 0.4
ENG_clear_color.y = 0.4
ENG_clear_color.z = 0.4

ENG_fill_color.x = 1
ENG_fill_color.y = 1
ENG_fill_color.z = 1

ENG_border_color.x = 0
ENG_border_color.y = 0
ENG_border_color.z = 0

ENG_internal_generate_ellipse_vert

screen ENG_canvas

$if ENG_SOFTWARE_MODE then
    _GLRENDER _BEHIND
    _delay 1
$else
    _GLRENDER _ONLY
$end if
_FPS 60
