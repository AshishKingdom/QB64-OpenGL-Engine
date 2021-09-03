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

SUB engine.draw (obj as engine_internal_type_mesh) '(m_ref as _unsigned long)
    if obj.used = 0 or obj.hidden = 1 then exit sub
    
    _glEnableClientState _GL_VERTEX_ARRAY
    if obj.geometry_type = ENGINE_GEOMETRY_ELLIPSE then
        'ellipse are rendered using pre-calculated normalized coordinates
        dim d as single, shape_detail as _unsigned integer, w as single, h as single
        w = _memget(obj.mesh_data, obj.mesh_data.OFFSET + ENGINE_VERT_MEMORY, single)
        h = _memget(obj.mesh_data, obj.mesh_data.OFFSET + ENGINE_VERT_MEMORY + 4, single)
        d =  (w + h) / 2
        if d>=0 and d<50 then 'we will select the array according to the size of the array.
            _glVertexPointer 3, _GL_FLOAT, 0, _offset(engine_internal_ev1())
            shape_detail = ubound(engine_internal_ev1)
        elseif d>=50 and d<700 then
            _glVertexPointer 3, _GL_FLOAT, 0, _offset(engine_internal_ev2())
            shape_detail = ubound(engine_internal_ev2)
        else
            _glVertexPointer 3, _GL_FLOAT, 0, _offset(engine_internal_ev3())
            shape_detail = ubound(engine_internal_ev3)
        end if
        _glPushMatrix
            _glTranslatef _memget(obj.mesh_data, obj.mesh_data.OFFSET, single),_memget(obj.mesh_data, obj.mesh_data.OFFSET + 4, single),0
            _glScalef w/2,h/2,1
            if obj.fill = 1 then
                _glColor3f obj.fill_color.x, obj.fill_color.y, obj.fill_color.z
                _glDrawArrays _GL_TRIANGLE_FAN, 0, shape_detail
            end if
            if obj.border = 1 then
                _glColor3f obj.border_color.x, obj.border_color.y, obj.border_color.z
                _glLineWidth engine_internal_mesh_list(m_ref).border_thickness
                _glDrawArrays _GL_LINE_LOOP, 0, shape_detail
            end if
        _glPopMatrix
    else
        _glVertexPointer 3, _GL_FLOAT, 24, obj.mesh_data.OFFSET
        select case obj.geometry_type
            case ENGINE_GEOMETRY_POINT
                if obj.border = 0 then goto engine_draw_skip_render 'border is 0, so no need of rendering it
                _glPointSize obj.border_thickness
                _glColor3f obj.border_color.x, obj.border_color.y, obj.border_color.z
                _glDrawArrays _GL_POINTS, 0, obj.mesh_total_v
            case ENGINE_GEOMETRY_LINE
                if obj.border = 0 then goto engine_draw_skip_render 'border is 0, so no need of rendering it
                _glLineWidth obj.border_thickness
                _glColor3f obj.border_color.x, obj.border_color.y, obj.border_color.z
                _glDrawArrays _GL_LINES, 0, obj.mesh_total_v
            case ENGINE_GEOMETRY_TRIANGLE
                if obj.fill = 1 then
                    _glColor3f obj.fill_color.x, obj.fill_color.y, obj.fill_color.z
                    _glDrawArrays _GL_TRIANGLES, 0, obj.mesh_total_v
                end if
                if obj.border = 1 then
                    _glColor3f obj.border_color.x, obj.border_color.y, obj.border_color.z
                    _glLineWidth obj.border_thickness
                    _glDrawArrays _GL_LINE_LOOP, 0, obj.mesh_total_v
                end if
            case ENGINE_GEOMETRY_QUAD
                if obj.fill = 1 then
                    _glColor3f obj.fill_color.x, obj.fill_color.y, obj.fill_color.z
                    _glDrawArrays _GL_QUADS, 0, obj.mesh_total_v
                end if
                if obj.border = 1 then
                     _glColor3f obj.border_color.x, obj.border_color.y, obj.border_color.z
                    _glLineWidth obj.border_thickness
                    _glDrawArrays _GL_LINE_LOOP, 0, obj.mesh_total_v
                end if
        end select
    end if

    engine_draw_skip_render:
    
    _glDisableClientState _GL_VERTEX_ARRAY
end sub

sub engine.set_background(c as _unsigned long)
    dim r as single, g as single, b as single
    r = _red32(c) : g = _green32(c) : b = _blue32(c)
    engine_clear_color.x = r/255
    engine_clear_color.y = g/255
    engine_clear_color.z = b/255
end sub

sub engine.enable_drawing ()
    engine_enable_drawing = 1
end sub

sub engine.disable_drawing ()
    engine_enable_drawing = 0
end sub

sub engine.enable_border (obj as engine_internal_type_mesh)
    obj.border = 1
end sub

sub engine.disable_border (obj as engine_internal_type_mesh)
    obj.border = 0
end sub

sub engine.enable_fill(obj as engine_internal_type_mesh)
    obj.fill = 1
end sub

sub engine.disable_fill (obj as engine_internal_type_mesh)
    obj.fill = 0
end sub

sub engine.set_border (obj as engine_internal_type_mesh, w as _unsigned integer)
    obj.border = engine_enable_border
    obj.border_thickness = w
end sub

sub engine.set_size (obj as engine_internal_type_mesh, w as single, h as single) 'sets the rect/ellipse width & height
    if obj.geometry_type <> ENGINE_GEOMETRY_ELLIPSE and obj.geometry_type <> ENGINE_GEOMETRY_QUAD then
        engine_internal_debug_log "engine.set_size() : geometry type of the mesh handle should only be ENGINE_GEOMETRY_ELLIPSE or ENGINE_GEOMETRY_QUAD. Invalid 'obj' passed", 1
        exit function
    end if
    engine_internal_debug_log "engine.set_size() : new size ("+str$(w)+","+str$(h)+") for mesh.", 1
        engine_internal_debug_log "engine.create.triangle() : WARNING! deleting the vertex data of 'obj' passed.", 1
    engine_internal_debug_log "engine.create.triangle() --> triange created", 1
        engine_internal_debug_log "engine.create.point() : WARNING! deleting the vertex data of 'obj' passed.", 1
    engine_internal_debug_log "engine.create.point() --> point created", 1
        engine_internal_debug_log "engine.create.line() : WARNING! deleting the vertex data of 'obj' passed.", 1
    engine_internal_debug_log "engine.create.line() --> line created", 1
        engine_internal_debug_log "engine.create.quad() : WARNING! deleting the vertex data of 'obj' passed.", 1
    engine_internal_debug_log "engine.create.quad() --> quad created", 1
        engine_internal_debug_log "engine.create.ellipse() : WARNING! deleting the vertex data of 'obj' passed.", 1
    engine_internal_debug_log "engine.create.ellipse() --> ellipse created", 1
    if obj.mesh_data.SIZE = 0 then
        engine_internal_debug_log "engine.destroy() : mesh handle ('obj') has no data.", 1
        exit sub
    end if
    if obj.used = 0 then
        engine_internal_debug_log "engine.destroy() : invalid mesh handle ('obj') passed.",1
        exit sub
    end if
    engine_internal_debug_log "engine.destroy() : mesh_handle destroyed successfully.",1
sub engine_internal_debug_log (a$, showtime as _byte) 'prints at console if it exists.
    if _console <> -1 then
        dim preDest as long
        
        preDest = _dest
        _dest _console
        if showtime = 1 then  print TIME$;" ";a$ else print a$
        _dest preDest
    end if
end sub

sub engine.mesh.printinfo (obj as engine_internal_type_mesh)
    if obj.mesh_data.SIZE = 0 then
        engine_internal_debug_log "engine.mesh.printinfo() : mesh handle ('m_ref') out of bounds.", 1
        exit sub
    end if
    if obj.used = 0 then
        engine_internal_debug_log "engine.mesh.printinfo() : invalid mesh handle ('m_ref') passed.",1
        exit sub
    end if
    engine_internal_debug_log "engine.mesh.info() : Mesh Information for handle - "+str$(m_ref), 1
    engine_internal_debug_log ".geometry_type = "+str$(obj.geometry_type), 1
    engine_internal_debug_log ".used = "+str$(obj.used), 1
    engine_internal_debug_log ".mesh_total_v = "+str$(obj.mesh_total_v), 1
    engine_internal_debug_log "vertex data for mesh -", 1
    dim i as _unsigned long
    for i = 0 to obj.mesh_total_v - 1
        engine_internal_debug_log "["+str$(i)+"] = ("+str$(_memget(obj.mesh_data, obj.mesh_data.OFFSET + i * ENGINE_VERT_MEMORY, single))+","+str$(_memget(obj.mesh_data, obj.mesh_data.OFFSET + i * ENGINE_VERT_MEMORY + 4, single))+","+str$(_memget(obj.mesh_data, obj.mesh_data.OFFSET + i * ENGINE_VERT_MEMORY + 8, single))+")", 1
    next
end sub
