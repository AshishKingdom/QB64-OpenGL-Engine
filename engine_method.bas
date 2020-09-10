'#################################################################
'--------------------+ QB64 OpenGL Engine +-----------------------
'                          [ALPHA] 
'                     By Ashish Kushwaha                          
'GitHub: https://github.com/AshishKindom/QB64-OpenGL-Engine
'LICENSE: GPL v3.0
'-----------------------------------------------------------------
'#################################################################

'#################################################################
'--------------------- RENDERING PART- ---------------------------
'#################################################################

SUB _GL ()
    $IF WIN THEN
        if _screenicon then exit sub
    $END IF
    if engine_enable_drawing = 0 then exit sub
    
    _glViewPort 0, 0, _width, _height
    _glClearColor engine_clear_color.x, engine_clear_color.y, engine_clear_color.z, 1
    _glClear _GL_COLOR_BUFFER_BIT OR _GL_DEPTH_BUFFER_BIT
    
    _glMatrixMode _GL_MODELVIEW
    _glLoadIdentity
    
    'code of transformation between 2 modes of coordinate system done here
    '1. QB64/Qbasic (DEFAULT): Default in which (0,0) is at the top-left corner of the screen.
    'and x & y increases as we move towards right and bottom respectively.
    '2. OpenGL: In OpenGL, (0,0) or (0,0,0) is at the center of the screen. Its behaviour is very much similar to Cartesian System.
    'x increases and decreases as we move towards right and left direction respectively w.r.t to (0,0) or (0,0,0)
    'y increases and decreases as we move towards top and bottom direction respectively w.r.t to (0,0) or (0,0,0)
    'z increases and decreases as we move backwards (or away from a plane) and forwards (or into the plane) respectively w.r.t. (0,0,0)
    if engine_coord_system = ENGINE_COORD_DEFAULT then
        _glTranslatef -1,1,0
        _glScalef 1/(0.5*_width(0)), -1/(0.5*_height(0)),1/(0.5*_width(0))
    end if
    
    engine.main
END SUB

SUB engine.draw (m_ref as _unsigned long)
    '@debug-part:start
    if m_ref>ubound(engine_internal_mesh_list) then
        engine_internal_debug_log "engine.draw() : mesh handle ('m_ref') out of bounds.", 1
        exit sub
    end if
    if engine_internal_mesh_list(m_ref).used = 0 then
        engine_internal_debug_log "engine.draw() : invalid mesh handle ('m_ref') passed.",1
        exit sub
    end if
    if engine_internal_mesh_list(m_ref).hidden = 1 then exit sub 'object is set to hidden. no need to render
    if engine_internal_mesh_list(m_ref).border = 0 and engine_internal_mesh_list(m_ref).fill = 0 then exit sub 'neither fill nor border enable. So, user forgot about hidden property?
    '@debug-part:end
    
    _glEnableClientState _GL_VERTEX_ARRAY
    _glVertexPointer 3, _GL_FLOAT, 13, _offset(engine_internal_vertex_list())+13*(engine_internal_mesh_list(m_ref).mesh_v_index)
    select case engine_internal_mesh_list(m_ref).geometry_type
        case ENGINE_GEOMETRY_POINT
            if engine_internal_mesh_list(m_ref).border = 0 then goto engine_draw_skip_render 'border is 0, so no need of rendering it
            _glPointSize engine_internal_mesh_list(m_ref).border_thickness
            _glColor3ub 0,0,0
            _glDrawArrays _GL_POINTS, 0, engine_internal_mesh_list(m_ref).mesh_total_v
        case ENGINE_GEOMETRY_LINE
            if engine_internal_mesh_list(m_ref).border = 0 then goto engine_draw_skip_render 'border is 0, so no need of rendering it
            _glLineWidth engine_internal_mesh_list(m_ref).border_thickness
            _glColor3ub 0,0,0
            _glDrawArrays _GL_LINES, 0, engine_internal_mesh_list(m_ref).mesh_total_v
        case ENGINE_GEOMETRY_TRIANGLE
            if engine_internal_mesh_list(m_ref).fill = 1 then
                _glColor3ub 255,255,255
                _glDrawArrays _GL_TRIANGLES, 0, engine_internal_mesh_list(m_ref).mesh_total_v
            end if
            if engine_internal_mesh_list(m_ref).border = 1 then
                _glColor3ub 0,0,0
                _glLineWidth engine_internal_mesh_list(m_ref).border_thickness
                _glDrawArrays _GL_LINE_LOOP, 0, engine_internal_mesh_list(m_ref).mesh_total_v
            end if
        case ENGINE_GEOMETRY_QUAD
            if engine_internal_mesh_list(m_ref).fill = 1 then
                _glColor3ub 255,255,255
                _glDrawArrays _GL_QUADS, 0, engine_internal_mesh_list(m_ref).mesh_total_v
            end if
            if engine_internal_mesh_list(m_ref).border = 1 then
                _glColor3ub 0,0,0
                _glLineWidth engine_internal_mesh_list(m_ref).border_thickness
                _glDrawArrays _GL_LINE_LOOP, 0, engine_internal_mesh_list(m_ref).mesh_total_v
            end if
    end select
    
    engine_draw_skip_render:
    
    _glDisableClientState _GL_VERTEX_ARRAY
end sub

sub engine.set_background(c as _unsigned long)
    dim r as single, g as single, b as single
    r = _red32(c) : g = _green32(c) : b = _blue32(c)
    engine_clear_color.x = r/255
    engine_clear_color.y = g/255
    engine_clear_color.z = b/255
    '@debug-part:start
    engine_internal_debug_log "engine.set_background() : background clearning color changed to ("+str$(r)+","+str$(g)+","+str$(b)+")",1
    '@debug-part:end
end sub

sub engine.enable_drawing ()
    engine_enable_drawing = 1
    '@debug-part:start
    engine_internal_debug_log "engine.enable_drawing() : drawing enabled", 1
    '@debug-part:end
end sub

sub engine.disable_drawing ()
    engine_enable_drawing = 0
    '@debug-part:start
    engine_internal_debug_log "engine.disable_drawing() : drawing disabled", 1
    '@debug-part:end
end sub

sub engine.enable_border (m_ref as _unsigned long)
    '@debug-part:start
    if m_ref>ubound(engine_internal_mesh_list) then
        engine_internal_debug_log "engine.draw() : mesh handle ('m_ref') out of bounds.", 1
        exit sub
    end if
    if engine_internal_mesh_list(m_ref).used = 0 then
        engine_internal_debug_log "engine.draw() : invalid mesh handle ('m_ref') passed.",1
        exit sub
    end if
    '@debug-part:end
    engine_internal_mesh_list(m_ref).border = 1
    '@debug-part:start
    engine_internal_debug_log "engine.enable_border() : border enabled for mesh <"+engine_internal_mesh_list(m_ref).ID+">", 1
    '@debug-part:end
end sub

sub engine.disable_border (m_ref as _unsigned long)
    '@debug-part:start
    if m_ref>ubound(engine_internal_mesh_list) then
        engine_internal_debug_log "engine.draw() : mesh handle ('m_ref') out of bounds.", 1
        exit sub
    end if
    if engine_internal_mesh_list(m_ref).used = 0 then
        engine_internal_debug_log "engine.draw() : invalid mesh handle ('m_ref') passed.",1
        exit sub
    end if
    '@debug-part:end
    engine_internal_mesh_list(m_ref).border = 0
    '@debug-part:start
    engine_internal_debug_log "engine.disable_border() : border disabled for mesh <"+engine_internal_mesh_list(m_ref).ID+">", 1
    '@debug-part:end
end sub

sub engine.enable_fill(m_ref as _unsigned long)
    '@debug-part:start
    if m_ref>ubound(engine_internal_mesh_list) then
        engine_internal_debug_log "engine.draw() : mesh handle ('m_ref') out of bounds.", 1
        exit sub
    end if
    if engine_internal_mesh_list(m_ref).used = 0 then
        engine_internal_debug_log "engine.draw() : invalid mesh handle ('m_ref') passed.",1
        exit sub
    end if
    '@debug-part:end
    engine_internal_mesh_list(m_ref).fill = 1
    '@debug-part:start
    engine_internal_debug_log "engine.enable_fill() : fill enabled for mesh <"+engine_internal_mesh_list(m_ref).ID+">", 1
    '@debug-part:end
end sub

sub engine.disable_fill (m_ref as _unsigned long)
    '@debug-part:start
    if m_ref>ubound(engine_internal_mesh_list) then
        engine_internal_debug_log "engine.draw() : mesh handle ('m_ref') out of bounds.", 1
        exit sub
    end if
    if engine_internal_mesh_list(m_ref).used = 0 then
        engine_internal_debug_log "engine.draw() : invalid mesh handle ('m_ref') passed.",1
        exit sub
    end if
    '@debug-part:end
    engine_internal_mesh_list(m_ref).fill = 0
    '@debug-part:start
    engine_internal_debug_log "engine.disable_drawing() : fill disabled for mesh <"+engine_internal_mesh_list(m_ref).ID+">", 1
    '@debug-part:end
end sub

sub engine.set_border (m_ref as _unsigned long, w as _unsigned integer)
    '@debug-part:start
    if m_ref>ubound(engine_internal_mesh_list) then
        engine_internal_debug_log "engine.draw() : mesh handle ('m_ref') out of bounds.", 1
        exit sub
    end if
    if engine_internal_mesh_list(m_ref).used = 0 then
        engine_internal_debug_log "engine.draw() : invalid mesh handle ('m_ref') passed.",1
        exit sub
    end if
    '@debug-part:end
    engine_internal_mesh_list(m_ref).border = 1
    engine_internal_mesh_list(m_ref).border_thickness = w
    '@debug-part:start
    engine_internal_debug_log "engine.set_border() : border thickness set to "+str$(w)+" for mesh for mesh <"+engine_internal_mesh_list(m_ref).ID+">", 1
    '@debug-part:end
end sub

'#################################################################
'---------------- OBJECT CREATION & DESTRUCTION-------------------
'#################################################################
function engine.create~& (mesh_type as integer, dimension as integer, v() as single)
    '@debug-part:start
    if dimension <> ENGINE_2D and dimension <> ENGINE_3D then
        engine_internal_debug_log "engine.create() : invalid 'dimension' passed", 1
        exit function
    end if
    if mesh_type<1 or mesh_type>4 then
        engine_internal_debug_log "engine.create() : invalid 'mesh_type' passed", 1
        exit function
    else
    '@debug-part:end
        dim found as _byte, i as _unsigned long, i2 as _unsigned long, i3 as _unsigned long, n_vert as _unsigned long
        dim tmp1 as integer, v_ref as _unsigned long
        'check if there is any element in engine_internal_mesh_list which can be reused.
        for i = 0 to ubound(engine_internal_mesh_list)
            if engine_internal_mesh_list(i).used = 0 then
                found = 1
                m_ref = i
                exit for
            end if
        next
        
        if found = 0 then 'means, all mesh elements are in use, so create a new one.
            m_ref = ubound(engine_internal_mesh_list) + 1
            redim _preserve engine_internal_mesh_list(m_ref) as engine_internal_type_mesh
        end if
        
        engine_internal_mesh_list(m_ref).geometry_type = mesh_type
        engine_internal_mesh_list(m_ref).used = 1
        engine_internal_mesh_list(m_ref).id = engine_internal_newID
        engine_internal_mesh_list(m_ref).fill = 1
        engine_internal_mesh_list(m_ref).border = 1
        engine_internal_mesh_list(m_ref).border_thickness = 2
        
        n_vert = ubound(v) - lbound(v) + 1 
        'verifying the dimension type with the array v() passed
        select case dimension
            case ENGINE_2D
                '@debug-part:start
                if n_vert mod 2 <> 0 then
                    engine_internal_debug_log "engine.create() : invalid number of elements in 'v()' passed", 1
                    engine_internal_mesh_list(m_ref).used = 0
                    engine_internal_mesh_list(m_ref).id = ""
                    exit function
                end if
                '@debug-part:end
                engine_internal_mesh_list(m_ref).mesh_total_v = n_vert / 2
            case ENGINE_3D
                '@debug-part:start
                if n_vert mod 3 <> 0 then
                    engine_internal_debug_log "engine.create() : invalid number of elements in 'v()' passed", 1
                    engine_internal_mesh_list(m_ref).used = 0
                    engine_internal_mesh_list(m_ref).id = ""
                    exit function
                end if
                '@debug-part:end
                engine_internal_mesh_list(m_ref).mesh_total_v = n_vert / 3
        end select
        
        found = 0
        'the value of mesh_type is set such that it is also equal to the number of vertices present in that shape.
        'like, the value of ENGINE_GEOMETRY_TRIANGLE and ENGINE_GEOMETRY_POINT is 3 and 1 respectively. And the number
        'of vertice(s) in these are also 3 and 1 respectively.
        
        'checking for free area in engine_internal_vertex_list() array.
        
        for i = 0 to ubound(engine_internal_vertex_list) - mesh_type + 1
            tmp1 = 0
            for i3 = i to i + mesh_type - 1
                tmp1 = tmp1 + engine_internal_vertex_list(i3).used
            next
            if tmp1 = 0 then
                found = 1
                
                engine_internal_mesh_list(m_ref).mesh_v_index = i
                
                if dimension = ENGINE_2D then tmp1 = 2 else tmp1 = 3 'storing number of elements per coordinate in tmp1

                for i3 = 0 to ubound(v) step tmp1
                    engine_internal_vertex_list(i).used = 1
                    engine_internal_vertex_list(i).v.x = v(i3)
                    engine_internal_vertex_list(i).v.y = v(i3+1)
                    if mesh_type = ENGINE_3D then engine_internal_vertex_list(i).v.z = v(i3+2)
                    i = i + 1
                next
                exit for
            end if
        next
        
        if found = 0 then
            'no free space found in the engine_internal_vertex_list() array where we can add vertices.
            'so, we'll create new space.
            i = ubound(engine_internal_vertex_list)
            redim _preserve engine_internal_vertex_list(i*2+mesh_type) as engine_internal_type_vertex

            'last try for a free space near the array upper found.
            for i2 = i - mesh_type + 1 to i 'mesh_type is used also being used as no. of vertice in the geometry type
                tmp1 = 0
                for i3 = i2 to i2 + mesh_type - 1
                    tmp1 = tmp1 + engine_internal_vertex_list(i3).used
                next
                if tmp1 = 0 then
                    found = 1
                    i = i2
                    exit for
                end if
            next
            
            if found = 0 then i = i + 1
            
            engine_internal_mesh_list(m_ref).mesh_v_index = i
            
            if dimension = ENGINE_2D then tmp1 = 2 else tmp1 = 3 'storing number of elements per coordinate in tmp1
            
            for i3 = 0 to ubound(v) step tmp1
                engine_internal_vertex_list(i).used = 1
                engine_internal_vertex_list(i).v.x = v(i3)
                engine_internal_vertex_list(i).v.y = v(i3+1)
                if mesh_type = ENGINE_3D then engine_internal_vertex_list(i).v.z = v(i3+2)
                i = i + 1
            next
        end if
        
        engine.create~& = m_ref
        '@debug-part:start
        engine_internal_debug_log "engine.create() : new mesh created with ID - <"+engine_internal_mesh_list(m_ref).ID+">", 1
        
    end if
    '@debug-part:end
end function

function engine.create.triangle~& (x1 as single, y1 as single, x2 as single, y2 as single,x3 as single, y3 as single)
    dim vert(5) as single
    vert(0) = x1 : vert(1) = y1
    vert(2) = x2 : vert(3) = y2
    vert(4) = x3 : vert(5) = y3
    '@debug-part:start
    engine_internal_debug_log "engine.create.triangle() --> engine.create()", 1
    '@debug-part:end
    engine.create.triangle~& = engine.create(ENGINE_GEOMETRY_TRIANGLE, ENGINE_2D, vert())
end function

function engine.create.point~& (x1 as single, y1 as single)
    dim vert(1) as single
    vert(0) = x1 : vert(1) = y1
    '@debug-part:start
    engine_internal_debug_log "engine.create.point() --> engine.create()", 1
    '@debug-part:end
    engine.create.point~& = engine.create(ENGINE_GEOMETRY_POINT, ENGINE_2D, vert())
end function

function engine.create.line~& (x1 as single, y1 as single, x2 as single, y2 as single)
    dim vert(3) as single
    vert(0) = x1 : vert(1) = y1
    vert(2) = x2 : vert(3) = y2
    '@debug-part:start
    engine_internal_debug_log "engine.create.line() --> engine.create()", 1
    '@debug-part:end
    engine.create.line~& = engine.create(ENGINE_GEOMETRY_LINE, ENGINE_2D, vert())
end function

function engine.create.quad~& (x1 as single, y1 as single, w as single, h as single)
    dim vert(7) as single
    vert(0) = x1 : vert(1) = y1
    vert(2) = x1+w : vert(3) = y1
    vert(4) = x1+w : vert(5) = y1+h
    vert(6) = x1 : vert(7) = y1+h
    '@debug-part:start
    engine_internal_debug_log "engine.create.quad() --> engine.create()", 1
    '@debug-part:end
    engine.create.quad~& = engine.create(ENGINE_GEOMETRY_QUAD, ENGINE_2D, vert())
end function

sub engine.destroy (m_ref as _unsigned long)
    '@debug-part:start
    if m_ref>ubound(engine_internal_mesh_list) then
        engine_internal_debug_log "engine.destroy() : mesh handle ('m_ref') out of bounds.", 1
        exit sub
    end if
    if engine_internal_mesh_list(m_ref).used = 0 then
        engine_internal_debug_log "engine.destroy() : invalid mesh handle ('m_ref') passed.",1
        exit sub
    end if
    '@debug-part:end
    dim i as _unsigned long
    for i = engine_internal_mesh_list(m_ref).mesh_v_index to engine_internal_mesh_list(m_ref).mesh_v_index + engine_internal_mesh_list(m_ref).mesh_total_v - 1
        engine_internal_vertex_list(i).used = 0
    next
    engine_internal_mesh_list(m_ref).used = 0
    '@debug-part:start
    engine_internal_debug_log "engine.destroy() : mesh_handle with ID <"+engine_internal_mesh_list(m_ref).ID+"> destroyed successfully.",1
    '@debug-part:end
    engine_internal_mesh_list(m_ref).ID = ""
    
end sub

'#################################################################
'------------------------- INTERNALS -----------------------------
'#################################################################
'@debug-part:start
sub engine_internal_debug_log (a$, showtime as _byte) 'prints at console if it exists.
    if _console <> -1 then
        dim preDest as long
        
        preDest = _dest
        _dest _console
        if showtime = 1 then  print TIME$;" ";a$ else print a$
        _dest preDest
    end if
end sub

sub engine.mesh.printinfo (m_ref as _unsigned long)
    if m_ref>ubound(engine_internal_mesh_list) then
        engine_internal_debug_log "engine.draw() : mesh handle ('m_ref') out of bounds.", 1
        exit sub
    end if
    if engine_internal_mesh_list(m_ref).used = 0 then
        engine_internal_debug_log "engine.draw() : invalid mesh handle ('m_ref') passed.",1
        exit sub
    end if
    engine_internal_debug_log "engine.mesh.info() : Mesh Information for handle - "+str$(m_ref), 1
    engine_internal_debug_log ".geometry_type = "+str$(engine_internal_mesh_list(m_ref).geometry_type), 1
    engine_internal_debug_log ".used = "+str$(engine_internal_mesh_list(m_ref).used), 1
    engine_internal_debug_log ".mesh_v_index = "+str$(engine_internal_mesh_list(m_ref).mesh_v_index), 1
    engine_internal_debug_log ".mesh_total_v = "+str$(engine_internal_mesh_list(m_ref).mesh_total_v), 1
    engine_internal_debug_log ".id = <"+engine_internal_mesh_list(m_ref).id+">", 1
    engine_internal_debug_log "vertex data for mesh -", 1
    dim i as _unsigned long
    for i = engine_internal_mesh_list(m_ref).mesh_v_index to engine_internal_mesh_list(m_ref).mesh_v_index + engine_internal_mesh_list(m_ref).mesh_total_v - 1
        engine_internal_debug_log "["+str$(i)+"] = ("+str$(engine_internal_vertex_list(i).v.x)+","+str$(engine_internal_vertex_list(i).v.y)+","+str$(engine_internal_vertex_list(i).v.z)+")", 1
    next
end sub
'@debug-part:end

function engine_internal_newID$ ()
    Dim newID as string, i as _unsigned long
    engine_internal_newID_retry:
    newID = ""
    for i = 1 to 32
        newID = newID + mid$("qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890", int(rnd*62)+1, 1)
    next
    'newID must be unique
    for i = 1 to ubound(engine_internal_mesh_list)
        if engine_internal_mesh_list(i).id = newID then goto engine_internal_newID_retry
    next
    
    engine_internal_newID$ = newID
end function
