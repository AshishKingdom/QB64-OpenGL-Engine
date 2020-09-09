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
    _glEnableClientState _GL_VERTEX_ARRAY
    _glVertexPointer 3, _GL_FLOAT, 13, _offset(engine_internal_vertex_list())+13*(engine_internal_mesh_list(m_ref).mesh_v_index)
    _glDrawArrays _GL_TRIANGLES, 0, engine_internal_mesh_list(m_ref).mesh_total_v
    _glDisableClientState _GL_VERTEX_ARRAY
end sub
'#################################################################
'---------------- OBJECT CREATION & DESTRUCTION-------------------
'#################################################################
function engine.create~& (mesh_type as integer, dimension as integer, v() as single)
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
        engine_internal_mesh_list(m_ref).used = -1
        engine_internal_mesh_list(m_ref).id = engine_internal_newID
        n_vert = ubound(v) - lbound(v) + 1 
        'verifying the dimension type with the array v() passed
        select case dimension
            case ENGINE_2D
                engine_internal_mesh_list(m_ref).mesh_total_v = n_vert / 2
            case ENGINE_3D
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
                    engine_internal_vertex_list(i).used = -1
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
                    tmp1 = engine_internal_vertex_list(i3).used
                next
                if tmp1 = 0 then
                    found = 1
                    i = i2
                    exit for
                end if
            next
            if found = 0 then i = i + 1
            engine_internal_mesh_list(m_ref).mesh_v_index = i
            if mesh_type = ENGINE_2D then tmp1 = 2 else tmp1 = 3 'storing number of elements per coordinate in tmp1
            for i3 = 0 to ubound(v) step tmp1
                engine_internal_vertex_list(i).used = -1
                engine_internal_vertex_list(i).v.x = v(i3)
                engine_internal_vertex_list(i).v.y = v(i3+1)
                if mesh_type = ENGINE_3D then engine_internal_vertex_list(i).v.z = v(i3+2)
                i = i + 1
            next
        end if
        engine.create~& = m_ref
end function
function engine.create.triangle~& (x1 as single, y1 as single, x2 as single, y2 as single,x3 as single, y3 as single)
    dim vert(5) as single
    vert(0) = x1 : vert(1) = y1
    vert(2) = x2 : vert(3) = y2
    vert(4) = x3 : vert(5) = y3
    engine.create.triangle~& = engine.create(ENGINE_GEOMETRY_TRIANGLE, ENGINE_2D, vert())
end function
sub engine.destroy (m_ref as _unsigned long)
    dim i as _unsigned long
    for i = engine_internal_mesh_list(m_ref).mesh_v_index to engine_internal_mesh_list(m_ref).mesh_v_index + engine_internal_mesh_list(m_ref).mesh_total_v - 1
        engine_internal_vertex_list(i).used = 0
    next
    engine_internal_mesh_list(m_ref).used = 0
    engine_internal_mesh_list(m_ref).ID = ""
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
