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
    
    
    $if ENG_SOFTWARE_MODE then
        'in software mode, all rendering is done with respect to ENG_canvas image handle (which is usually our screen)
        _glViewPort 0, 0, _width(ENG_canvas), _height(ENG_canvas)
    $else
        if ENG_enable_drawing = 0 then exit sub
        _glViewPort 0, 0, _width(0), _height(0)
        _glClearColor ENG_clear_color.x, ENG_clear_color.y, ENG_clear_color.z, 1
    $end if
    
    _glClear _GL_COLOR_BUFFER_BIT
    
    _glMatrixMode _GL_MODELVIEW
    _glLoadIdentity
    
    'code of transformation between 2 modes of coordinate system done here
    '1. QB64/Qbasic (DEFAULT): Default in which (0,0) is at the top-left corner of the screen.
    'and x & y increases as we move towards right and bottom respectively.
    '2. OpenGL: In OpenGL, (0,0) or (0,0,0) is at the center of the screen. Its behaviour is very much similar to Cartesian System.
    'x increases and decreases as we move towards right and left direction respectively w.r.t to (0,0) or (0,0,0)
    'y increases and decreases as we move towards top and bottom direction respectively w.r.t to (0,0) or (0,0,0)
    'z increases and decreases as we move backwards (or away from a plane) and forwards (or into the plane) respectively w.r.t. (0,0,0)
    if ENG_coord_system = ENG_COORD_DEFAULT then
        $if ENG_SOFTWARE_MODE then
            _glTranslatef -1,-1,0
            _glScalef 1/(0.5*_width(ENG_canvas)), 1/(0.5*_height(ENG_canvas)),1
        $else
            _glTranslatef -1,1,0
            _glScalef 1/(0.5*_width(0)), -1/(0.5*_height(0)), 1
        $end if
    end if
    
    $if ENG_SOFTWARE_MODE then
        if len(ENG_draw_calls) > 0 and (len(ENG_draw_calls) mod (34 + 2 * ENG_offset_size)) = 0 then
            'initialization
            dim block_size as _byte
            dim i as _unsigned long
            dim as _byte geometry_type, used, fill, border, border_thickness, hidden
            dim as ENG_internal_type_vec3 fill_color, border_color
            dim as _offset size, __offset
            dim mesh_total_v as _unsigned long
            
            block_size = 34 + 2 * ENG_offset_size
            
            for i = 1 to len(ENG_draw_calls) step block_size
                'extract data from each block of call data string
                'check ENG.draw to know how it is store
                geometry_type = _cv(_byte, mid$(ENG_draw_calls, i, 1))
                used = _cv(_byte, mid$(ENG_draw_calls, i+1, 1))
                fill = _cv(_byte, mid$(ENG_draw_calls, i+2, 1))
                'NOTE:
                'to make copy of pixel data easier, we will swap Red and Green color channels
                fill_color.z = _cv(single, mid$(ENG_draw_calls, i+3, 4))
                fill_color.y = _cv(single, mid$(ENG_draw_calls, i+7, 4))
                fill_color.x = _cv(single, mid$(ENG_draw_calls, i+11, 4))
                border = _cv(_byte, mid$(ENG_draw_calls, i+15, 1))
                border_color.z = _cv(single, mid$(ENG_draw_calls, i+16, 4))
                border_color.y = _cv(single, mid$(ENG_draw_calls, i+20, 4))
                border_color.x = _cv(single, mid$(ENG_draw_calls, i+24, 4))
                border_thickness = _cv(_byte, mid$(ENG_draw_calls, i+28, 1))
                hidden = _cv(_byte, mid$(ENG_draw_calls, i+29, 1))
                mesh_total_v = _cv(_unsigned long, mid$(ENG_draw_calls, i+30, 4))
                size = _cv(_offset, mid$(ENG_draw_calls, i+34, ENG_offset_size))
                __offset = _cv(_offset, mid$(ENG_draw_calls, i+34+ENG_offset_size, ENG_offset_size))
                
                ' ENG_internal_debug_log ".geometry_type = "+str$(geometry_type),1
                ' ENG_internal_debug_log ".used = "+str$(used),1
                ' ENG_internal_debug_log ".fill = "+str$(fill),1
                ' ENG_internal_debug_log ".fill_color.x = "+str$(fill_color.x),1
                ' ENG_internal_debug_log ".fill_color.y = "+str$(fill_color.y),1
                ' ENG_internal_debug_log ".fill_color.z = "+str$(fill_color.z),1
                ' ENG_internal_debug_log ".border = "+str$(border),1
                ' ENG_internal_debug_log ".border_color.x = "+str$(border_color.x),1
                ' ENG_internal_debug_log ".border_color.y = "+str$(border_color.y),1
                ' ENG_internal_debug_log ".border_color.z = "+str$(border_color.z),1
                ' ENG_internal_debug_log ".border_thickness = "+str$(border_thickness),1
                ' ENG_internal_debug_log ".hidden = "+str$(hidden),1
                ' ENG_internal_debug_log ".mesh_total_v = "+str$(mesh_total_v),1
                ' ENG_internal_debug_log ".size = "+str$(size),1
                ' ENG_internal_debug_log ".offset = "+str$(__offset),1
                ' ENG_internal_debug_log "", 1
                
                'render stuffs using extracted data
                
                'below code was copied from SUB ENG.draw, with little modifications
                _glEnableClientState _GL_VERTEX_ARRAY
                if geometry_type = ENG_GEOMETRY_ELLIPSE then
                    'ellipse are rendered using pre-calculated normalized coordinates
                    dim d as single, shape_detail as _unsigned integer, w as single, h as single
                    $checking:off
                    'HACK: ENG_mem is treated as "dummy" variable here
                    w = _memget(ENG_mem, __offset + ENG_VERT_MEMORY, single)
                    h = _memget(ENG_mem, __offset + ENG_VERT_MEMORY + 4, single)
                    $checking:on
                    d =  (w + h) / 2
                    if d>=0 and d<50 then 'we will select the array according to the size of the array.
                        _glVertexPointer 3, _GL_FLOAT, 0, _offset(ENG_internal_ev1())
                        shape_detail = ubound(ENG_internal_ev1)
                    elseif d>=50 and d<700 then
                        _glVertexPointer 3, _GL_FLOAT, 0, _offset(ENG_internal_ev2())
                        shape_detail = ubound(ENG_internal_ev2)
                    else
                        _glVertexPointer 3, _GL_FLOAT, 0, _offset(ENG_internal_ev3())
                        shape_detail = ubound(ENG_internal_ev3)
                    end if
                    _glPushMatrix
                        $checking:off
                        _glTranslatef _memget(ENG_mem, __offset, single),_memget(ENG_mem, __offset + 4, single),0
                        $checking:on
                        _glScalef w/2,h/2,1
                        if fill = 1 then
                            _glColor3f fill_color.x, fill_color.y, fill_color.z
                            _glDrawArrays _GL_TRIANGLE_FAN, 0, shape_detail
                        end if
                        if border = 1 then
                            _glColor3f border_color.x, border_color.y, border_color.z
                            _glLineWidth border_thickness
                            _glDrawArrays _GL_LINE_LOOP, 0, shape_detail
                        end if
                    _glPopMatrix
                else
                    _glVertexPointer 3, _GL_FLOAT, 24, __offset
                    select case geometry_type
                        case ENG_GEOMETRY_POINT
                            if border = 0 then goto ENG_draw_skip_render 'border is 0, so no need of rendering it
                            _glPointSize border_thickness
                            _glColor3f border_color.x, border_color.y, border_color.z
                            _glDrawArrays _GL_POINTS, 0, mesh_total_v
                        case ENG_GEOMETRY_LINE
                            if border = 0 then goto ENG_draw_skip_render 'border is 0, so no need of rendering it
                            _glLineWidth border_thickness
                            _glColor3f border_color.x, border_color.y, border_color.z
                            _glDrawArrays _GL_LINES, 0, mesh_total_v
                        case ENG_GEOMETRY_TRIANGLE
                            if fill = 1 then
                                _glColor3f fill_color.x, fill_color.y, fill_color.z
                                _glDrawArrays _GL_TRIANGLES, 0, mesh_total_v
                            end if
                            if border = 1 then
                                _glColor3f border_color.x, border_color.y, border_color.z
                                _glLineWidth border_thickness
                                _glDrawArrays _GL_LINE_LOOP, 0, mesh_total_v
                            end if
                        case ENG_GEOMETRY_QUAD
                            if fill = 1 then
                                _glColor3f fill_color.x, fill_color.y, fill_color.z
                                _glDrawArrays _GL_QUADS, 0, mesh_total_v
                            end if
                            if border = 1 then
                                 _glColor3f border_color.x, border_color.y, border_color.z
                                _glLineWidth border_thickness
                                _glDrawArrays _GL_LINE_LOOP, 0, mesh_total_v
                            end if
                    end select
                end if
                _glDisableClientState _GL_VERTEX_ARRAY
                ENG_draw_skip_render:
            next
            _glFlush
            'now, we have to copy this data to our software screen
            ' ENG_internal_debug_log ".SIZE : "+str$((ENG_mem.SIZE))+" len(ENG_pixel_data()) : "+str$(len(ENG_pixel_data())),1
             ' ENG_internal_debug_log "_width(ENG_canvas) : "+str$(_width(ENG_canvas2))+" & _height(ENG_canvas2) : "+str$(_height(ENG_canvas)),1
            _glReadBuffer _GL_BACK
            _glPixelStorei _GL_UNPACK_ALIGNMENT, 1
            _glReadPixels 0, 0, _WIDTH(ENG_canvas), _HEIGHT(ENG_canvas), _GL_RGBA, _GL_UNSIGNED_BYTE, _offset(ENG_pixel_data())
            _memput ENG_mem, ENG_mem.OFFSET, ENG_pixel_data()
            _putimage , ENG_canvas2, ENG_canvas
            ENG_draw_calls = ""
        end if
    $else
        ENG.main
    $end if
END SUB

SUB ENG.draw (obj as ENG_type_mesh) '(m_ref as _unsigned long)
    if obj.used = 0 or obj.hidden = 1 then exit sub
    
    $if ENG_SOFTWARE_MODE then
        ENG_draw_calls = ENG_draw_calls + _mk$(_byte, obj.geometry_type) '.geometry_type (1 byte)
        ENG_draw_calls = ENG_draw_calls + _mk$(_byte, obj.used) '.used (1 byte)
        ENG_draw_calls = ENG_draw_calls + _mk$(_byte, obj.fill) '.fill (1 byte)
        ENG_draw_calls = ENG_draw_calls + _mk$(single, obj.fill_color.x) '.fill_color.x (4 byte)
        ENG_draw_calls = ENG_draw_calls + _mk$(single, obj.fill_color.y) '.fill_color.y (4 byte)
        ENG_draw_calls = ENG_draw_calls + _mk$(single, obj.fill_color.z) '.fill_color.z (4 byte)
        ENG_draw_calls = ENG_draw_calls + _mk$(_byte, obj.border) '.border (1 byte)
        ENG_draw_calls = ENG_draw_calls + _mk$(single, obj.border_color.x) '.border_color.x (4 byte)
        ENG_draw_calls = ENG_draw_calls + _mk$(single, obj.border_color.y) '.border_color.y (4 byte)
        ENG_draw_calls = ENG_draw_calls + _mk$(single, obj.border_color.z) '.border_color.z (4 byte)
        ENG_draw_calls = ENG_draw_calls + _mk$(_byte, obj.border_thickness) '.border_thickness (1 byte)
        ENG_draw_calls = ENG_draw_calls + _mk$(_byte, obj.hidden) '.hidden (1 byte)
        ENG_draw_calls = ENG_draw_calls + _mk$(_unsigned long, obj.mesh_total_v) '.mesh_total_v (4 byte)
        ENG_draw_calls = ENG_draw_calls + _mk$(_offset, obj.mesh_data.SIZE) '.mesh_data.SIZE (N bytes: size depends on system)
        ENG_draw_calls = ENG_draw_calls + _mk$(_offset, obj.mesh_data.OFFSET) '.mesh_data.OFFSET (N bytes : size depends on system)
        'total size = 2N + 34
    $else
        
        _glEnableClientState _GL_VERTEX_ARRAY
        if obj.geometry_type = ENG_GEOMETRY_ELLIPSE then
            'ellipse are rendered using pre-calculated normalized coordinates
            dim d as single, shape_detail as _unsigned integer, w as single, h as single
            w = _memget(obj.mesh_data, obj.mesh_data.OFFSET + ENG_VERT_MEMORY, single)
            h = _memget(obj.mesh_data, obj.mesh_data.OFFSET + ENG_VERT_MEMORY + 4, single)
            d =  (w + h) / 2
            if d>=0 and d<50 then 'we will select the array according to the size of the array.
                _glVertexPointer 3, _GL_FLOAT, 0, _offset(ENG_internal_ev1())
                shape_detail = ubound(ENG_internal_ev1)
            elseif d>=50 and d<700 then
                _glVertexPointer 3, _GL_FLOAT, 0, _offset(ENG_internal_ev2())
                shape_detail = ubound(ENG_internal_ev2)
            else
                _glVertexPointer 3, _GL_FLOAT, 0, _offset(ENG_internal_ev3())
                shape_detail = ubound(ENG_internal_ev3)
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
                    _glLineWidth obj.border_thickness
                    _glDrawArrays _GL_LINE_LOOP, 0, shape_detail
                end if
            _glPopMatrix
        else
            _glVertexPointer 3, _GL_FLOAT, 24, obj.mesh_data.OFFSET
            select case obj.geometry_type
                case ENG_GEOMETRY_POINT
                    if obj.border = 0 then goto ENG_draw_skip_render 'border is 0, so no need of rendering it
                    _glPointSize obj.border_thickness
                    _glColor3f obj.border_color.x, obj.border_color.y, obj.border_color.z
                    _glDrawArrays _GL_POINTS, 0, obj.mesh_total_v
                case ENG_GEOMETRY_LINE
                    if obj.border = 0 then goto ENG_draw_skip_render 'border is 0, so no need of rendering it
                    _glLineWidth obj.border_thickness
                    _glColor3f obj.border_color.x, obj.border_color.y, obj.border_color.z
                    _glDrawArrays _GL_LINES, 0, obj.mesh_total_v
                case ENG_GEOMETRY_TRIANGLE
                    if obj.fill = 1 then
                        _glColor3f obj.fill_color.x, obj.fill_color.y, obj.fill_color.z
                        _glDrawArrays _GL_TRIANGLES, 0, obj.mesh_total_v
                    end if
                    if obj.border = 1 then
                        _glColor3f obj.border_color.x, obj.border_color.y, obj.border_color.z
                        _glLineWidth obj.border_thickness
                        _glDrawArrays _GL_LINE_LOOP, 0, obj.mesh_total_v
                    end if
                case ENG_GEOMETRY_QUAD
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
        _glDisableClientState _GL_VERTEX_ARRAY
        ENG_draw_skip_render:
    $end if

    
end sub

$if ENG_SOFTWARE_MODE then
    sub ENG.screen_size (w as integer, h as integer)
        dim temp_image as Long
        
        temp_image = _newimage(w, h, 32)
        screen temp_image
        
        ENG_draw_calls = ""
        _memfree ENG_mem
        redim ENG_pixel_data(1 to w * h * 4) as _unsigned _byte
        _freeimage ENG_canvas
        _freeimage ENG_canvas2
        ENG_canvas = temp_image
        ENG_canvas2 = _copyimage(ENG_canvas)
        ENG_mem = _memimage(ENG_canvas2)
        _delay 1
        
    end sub
$end if

$if ENG_SOFTWARE_MODE then
else
    sub ENG.set_background(c as _unsigned long)
        dim r as single, g as single, b as single
        r = _red32(c) : g = _green32(c) : b = _blue32(c)
        ENG_clear_color.x = r/255
        ENG_clear_color.y = g/255
        ENG_clear_color.z = b/255
    end sub
$end if

sub ENG.enable_drawing ()
    ENG_enable_drawing = 1
end sub

sub ENG.disable_drawing ()
    ENG_enable_drawing = 0
end sub

sub ENG.enable_border (obj as ENG_type_mesh)
    obj.border = 1
end sub

sub ENG.disable_border (obj as ENG_type_mesh)
    obj.border = 0
end sub

sub ENG.enable_fill(obj as ENG_type_mesh)
    obj.fill = 1
end sub

sub ENG.disable_fill (obj as ENG_type_mesh)
    obj.fill = 0
end sub

sub ENG.set_border (obj as ENG_type_mesh, w as _unsigned integer)
    obj.border = ENG_enable_border
    obj.border_thickness = w
end sub

sub ENG.set_size (obj as ENG_type_mesh, w as single, h as single) 'sets the rect/ellipse width & height
    if obj.geometry_type = ENG_GEOMETRY_ELLIPSE then
        ENG_internal_memput2 obj.mesh_data, ENG_VERT_MEMORY, w, h 'set new width and height
    else
        dim x1 as single, y1 as single
        x1 = _memget(obj.mesh_data, obj.mesh_data.OFFSET, single)
        y1 = _memget(obj.mesh_data, obj.mesh_data.OFFSET + 4, single)
        
        ENG_internal_memput1 obj.mesh_data, ENG_VERT_MEMORY, x1+w '[1]
        ENG_internal_memput2 obj.mesh_data, ENG_VERT_MEMORY*2, x1+w, y1+h '[2], [2]
        ENG_internal_memput1 obj.mesh_data, ENG_VERT_MEMORY*3 + 4, y1+h  ',[3]
    end if
end sub

'#################################################################
'---------------- OBJECT CREATION & DESTRUCTION-------------------
'#################################################################

sub ENG.create.triangle (obj as ENG_type_mesh, x1 as single, y1 as single, x2 as single, y2 as single,x3 as single, y3 as single)

    if obj.mesh_data.SIZE <> 0 then
        _memfree obj.mesh_data
    end if
    obj.mesh_data = _memnew(ENG_VERT_MEMORY * 3)
    
    'put all the data in the mem block
    ENG_internal_memput3 obj.mesh_data, 0, x1, y1, 0
    ENG_internal_memput3 obj.mesh_data, ENG_VERT_MEMORY, x2, y2, 0
    ENG_internal_memput3 obj.mesh_data, ENG_VERT_MEMORY * 2, x3, y3, 0
    
    obj.geometry_type = ENG_GEOMETRY_TRIANGLE
    obj.used = 1
    obj.fill = ENG_enable_fill
    obj.fill_color =  ENG_fill_color
    obj.border = ENG_enable_border
    obj.border_color = ENG_border_color
    obj.border_thickness = ENG_border_thickness
    obj.mesh_total_v = 3
    
end sub

sub ENG.create.point (obj as ENG_type_mesh, x1 as single, y1 as single)
    if obj.mesh_data.SIZE <> 0 then
        _memfree obj.mesh_data
    end if
    
    obj.mesh_data = _memnew(ENG_VERT_MEMORY)
    ENG_internal_memput3 obj.mesh_data, 0, x1, y1, 0
    
    obj.geometry_type = ENG_GEOMETRY_POINT
    obj.used = 1
    obj.fill = ENG_enable_fill
    obj.fill_color =  ENG_fill_color
    obj.border = ENG_enable_border
    obj.border_color = ENG_border_color
    obj.border_thickness = ENG_border_thickness
    obj.mesh_total_v = 1
    
end sub

sub ENG.create.line (obj as ENG_type_mesh, x1 as single, y1 as single, x2 as single, y2 as single)
    if obj.mesh_data.SIZE <> 0 then
        _memfree obj.mesh_data
    end if
    
    obj.mesh_data = _memnew(ENG_VERT_MEMORY*2)
    ENG_internal_memput3 obj.mesh_data, 0, x1, y1, 0
    ENG_internal_memput3 obj.mesh_data, ENG_VERT_MEMORY, x2, y2, 0
    
    obj.geometry_type = ENG_GEOMETRY_LINE
    obj.used = 1
    obj.fill = ENG_enable_fill
    obj.fill_color =  ENG_fill_color
    obj.border = ENG_enable_border
    obj.border_color = ENG_border_color
    obj.border_thickness = ENG_border_thickness
    obj.mesh_total_v = 2
    
end sub

sub ENG.create.quad (obj as ENG_type_mesh, x1 as single, y1 as single, w as single, h as single)
    if obj.mesh_data.SIZE <> 0 then
        _memfree obj.mesh_data
    end if
    
    obj.mesh_data = _memnew(ENG_VERT_MEMORY*4)
    ENG_internal_memput3 obj.mesh_data, 0, x1, y1, 0
    ENG_internal_memput3 obj.mesh_data, ENG_VERT_MEMORY, x1+w, y1, 0
    ENG_internal_memput3 obj.mesh_data, ENG_VERT_MEMORY*2, x1+w, y1+h, 0
    ENG_internal_memput3 obj.mesh_data, ENG_VERT_MEMORY*3, x1, y1+h, 0
    
    obj.geometry_type = ENG_GEOMETRY_QUAD
    obj.used = 1
    obj.fill = ENG_enable_fill
    obj.fill_color =  ENG_fill_color
    obj.border = ENG_enable_border
    obj.border_color = ENG_border_color
    obj.border_thickness = ENG_border_thickness
    obj.mesh_total_v = 4
end sub

sub ENG.create.ellipse (obj as ENG_type_mesh, x1 as single, y1 as single, w as single, h as single)
    if obj.mesh_data.SIZE <> 0 then
        _memfree obj.mesh_data
    end if
    
    obj.mesh_data = _memnew(ENG_VERT_MEMORY*2)
    ENG_internal_memput3 obj.mesh_data, 0, x1, y1, 0
    ENG_internal_memput3 obj.mesh_data, ENG_VERT_MEMORY, w, h, 0
    
    obj.geometry_type = ENG_GEOMETRY_ELLIPSE
    obj.used = 1
    obj.fill = ENG_enable_fill
    obj.fill_color =  ENG_fill_color
    obj.border = ENG_enable_border
    obj.border_color = ENG_border_color
    obj.border_thickness = ENG_border_thickness
    obj.mesh_total_v = 0
    
end sub

sub ENG.destroy (obj as ENG_type_mesh)

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

sub ENG_internal_generate_ellipse_vert()
    dim i as single, j as _unsigned integer
    j = 1
    for i = 0 to _pi(2) step _pi(2/32)
        ENG_internal_ev1(j).x = cos(i) : ENG_internal_ev1(j).y = sin(i)
        j = j + 1
    next
    j = 1
    for i = 0 to _pi(2) step _pi(2/100)
        ENG_internal_ev2(j).x = cos(i) : ENG_internal_ev2(j).y = sin(i)
        j = j + 1
    next
    j = 1
    for i = 0 to _pi(2) step _pi(2/500)
        ENG_internal_ev3(j).x = cos(i) : ENG_internal_ev3(j).y = sin(i)
        j = j + 1
    next
end sub

sub ENG_internal_memput1 (m as _mem, p as _unsigned long, d1 as single)
    _memput m, m.OFFSET + p, d1
end sub

sub ENG_internal_memput2 (m as _mem, p as _unsigned long, d1 as single, d2 as single)
    _memput m, m.OFFSET + p, d1
    _memput m, m.OFFSET + p + 4, d2
end sub

sub ENG_internal_memput3 (m as _mem, p as _unsigned long, d1 as single, d2 as single, d3 as single)
    _memput m, m.OFFSET + p, d1
    _memput m, m.OFFSET + p + 4, d2
    _memput m, m.OFFSET + p + 8, d3
end sub


