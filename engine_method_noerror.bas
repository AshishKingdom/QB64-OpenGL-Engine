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
    if obj.geometry_type = ENGINE_GEOMETRY_ELLIPSE then
        engine_internal_memput2 obj.mesh_data, ENGINE_VERT_MEMORY, w, h 'set new width and height
    else
        dim x1 as single, y1 as single
        x1 = _memget(obj.mesh_data, obj.mesh_data.OFFSET, single)
        y1 = _memget(obj.mesh_data, obj.mesh_data.OFFSET + 4, single)
        engine_internal_memput1 obj.mesh_data, ENGINE_VERT_MEMORY, x1+w '[1]
        engine_internal_memput2 obj.mesh_data, ENGINE_VERT_MEMORY*2, x1+w, y1+h '[2], [2]
        engine_internal_memput1 obj.mesh_data, ENGINE_VERT_MEMORY*3 + 4, y1+h  ',[3]
    end if
end sub
'#################################################################
'---------------- OBJECT CREATION & DESTRUCTION-------------------
'#################################################################
sub engine.create.triangle (obj as engine_internal_type_mesh, x1 as single, y1 as single, x2 as single, y2 as single,x3 as single, y3 as single)
    if obj.mesh_data.SIZE <> 0 then
        _memfree obj.mesh_data
    end if
    obj.mesh_data = _memnew(ENGINE_VERT_MEMORY * 3)
    'put all the data in the mem block
    engine_internal_memput3 obj.mesh_data, 0, x1, y1, 0
    engine_internal_memput3 obj.mesh_data, ENGINE_VERT_MEMORY, x2, y2, 0
    engine_internal_memput3 obj.mesh_data, ENGINE_VERT_MEMORY * 2, x3, y3, 0
    obj.geometry_type = ENGINE_GEOMETRY_TRIANGLE
    obj.used = 1
    obj.fill = engine_enable_fill
    obj.fill_color =  engine_fill_color
    obj.border = engine_enable_border
    obj.border_color = engine_border_color
    obj.border_thickness = engine_border_thickness
    obj.mesh_total_v = 3
end sub
sub engine.create.point (obj as engine_internal_type_mesh, x1 as single, y1 as single)
    if obj.mesh_data.SIZE <> 0 then
        _memfree obj.mesh_data
    end if
    obj.mesh_data = _memnew(ENGINE_VERT_MEMORY)
    engine_internal_memput3 obj.mesh_data, 0, x1, y1, 0
    obj.geometry_type = ENGINE_GEOMETRY_POINT
    obj.used = 1
    obj.fill = engine_enable_fill
    obj.fill_color =  engine_fill_color
    obj.border = engine_enable_border
    obj.border_color = engine_border_color
    obj.border_thickness = engine_border_thickness
    obj.mesh_total_v = 1
end sub
sub engine.create.line (obj as engine_internal_type_mesh, x1 as single, y1 as single, x2 as single, y2 as single)
    if obj.mesh_data.SIZE <> 0 then
        _memfree obj.mesh_data
    end if
    obj.mesh_data = _memnew(ENGINE_VERT_MEMORY*2)
    engine_internal_memput3 obj.mesh_data, 0, x1, y1, 0
    engine_internal_memput3 obj.mesh_data, ENGINE_VERT_MEMORY, x2, y2, 0
    obj.geometry_type = ENGINE_GEOMETRY_LINE
    obj.used = 1
    obj.fill = engine_enable_fill
    obj.fill_color =  engine_fill_color
    obj.border = engine_enable_border
    obj.border_color = engine_border_color
    obj.border_thickness = engine_border_thickness
    obj.mesh_total_v = 2
end sub
sub engine.create.quad (obj as engine_internal_type_mesh, x1 as single, y1 as single, w as single, h as single)
    if obj.mesh_data.SIZE <> 0 then
        _memfree obj.mesh_data
    end if
    obj.mesh_data = _memnew(ENGINE_VERT_MEMORY*4)
    engine_internal_memput3 obj.mesh_data, 0, x1, y1, 0
    engine_internal_memput3 obj.mesh_data, ENGINE_VERT_MEMORY, x1+w, y1, 0
    engine_internal_memput3 obj.mesh_data, ENGINE_VERT_MEMORY*2, x1+w, y1+h, 0
    engine_internal_memput3 obj.mesh_data, ENGINE_VERT_MEMORY*3, x1, y1+h, 0
    obj.geometry_type = ENGINE_GEOMETRY_QUAD
    obj.used = 1
    obj.fill = engine_enable_fill
    obj.fill_color =  engine_fill_color
    obj.border = engine_enable_border
    obj.border_color = engine_border_color
    obj.border_thickness = engine_border_thickness
    obj.mesh_total_v = 4
end sub
sub engine.create.ellipse (obj as engine_internal_type_mesh, x1 as single, y1 as single, w as single, h as single)
    if obj.mesh_data.SIZE <> 0 then
        _memfree obj.mesh_data
    end if
    obj.mesh_data = _memnew(ENGINE_VERT_MEMORY*2)
    engine_internal_memput3 obj.mesh_data, 0, x1, y1, 0
    engine_internal_memput3 obj.mesh_data, ENGINE_VERT_MEMORY, w, h, 0
    obj.geometry_type = ENGINE_GEOMETRY_ELLIPSE
    obj.used = 1
    obj.fill = engine_enable_fill
    obj.fill_color =  engine_fill_color
    obj.border = engine_enable_border
    obj.border_color = engine_border_color
    obj.border_thickness = engine_border_thickness
    obj.mesh_total_v = 0
end sub
sub engine.destroy (obj as engine_internal_type_mesh)
    ' dim i as _unsigned long
    ' for i = engine_internal_mesh_list(m_ref).mesh_v_index to engine_internal_mesh_list(m_ref).mesh_v_index + engine_internal_mesh_list(m_ref).mesh_total_v - 1
        ' engine_internal_vertex_list(i).used = 0
    ' next
    _memfree obj.mesh_data
    obj.geometry_type = 0
    obj.fill = 0
    obj.border = 0
    obj.hidden = 0
    obj.mesh_total_v = 0
    obj.border_thickness = 0
    obj.fill_color.x = 0 : obj.fill_color.y = 0 : obj.fill_color.z = 0
    obj.border_color.x = 0 : obj.border_color.y = 0 : obj.border_color.z = 0
    obj.used = 0
end sub
'#################################################################
'------------------------- INTERNALS -----------------------------
'#################################################################
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
sub engine_internal_generate_ellipse_vert()
    dim i as single, j as _unsigned integer
    j = 1
    for i = 0 to _pi(2) step _pi(2/32)
        engine_internal_ev1(j).x = cos(i) : engine_internal_ev1(j).y = sin(i)
        j = j + 1
    next
    j = 1
    for i = 0 to _pi(2) step _pi(2/100)
        engine_internal_ev2(j).x = cos(i) : engine_internal_ev2(j).y = sin(i)
        j = j + 1
    next
    j = 1
    for i = 0 to _pi(2) step _pi(2/500)
        engine_internal_ev3(j).x = cos(i) : engine_internal_ev3(j).y = sin(i)
        j = j + 1
    next
end sub
sub engine_internal_memput1 (m as _mem, p as _unsigned long, d1 as single)
    _memput m, m.OFFSET + p, d1
end sub
sub engine_internal_memput2 (m as _mem, p as _unsigned long, d1 as single, d2 as single)
    _memput m, m.OFFSET + p, d1
    _memput m, m.OFFSET + p + 4, d2
end sub
sub engine_internal_memput3 (m as _mem, p as _unsigned long, d1 as single, d2 as single, d3 as single)
    _memput m, m.OFFSET + p, d1
    _memput m, m.OFFSET + p + 4, d2
    _memput m, m.OFFSET + p + 8, d3
end sub
