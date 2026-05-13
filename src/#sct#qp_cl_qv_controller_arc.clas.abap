CLASS /sct/qp_cl_qv_controller_arc DEFINITION
  PUBLIC
  INHERITING FROM /sct/qp_cl_qv_controller
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS on_fcode   REDEFINITION.
    METHODS set_active REDEFINITION.

  PROTECTED SECTION.
    METHODS do_mod_arc_restore IMPORTING is_base TYPE /sct/qp_s_base
                               RAISING   /sct/qp_cx_error.

  PRIVATE SECTION.
ENDCLASS.


CLASS /sct/qp_cl_qv_controller_arc IMPLEMENTATION.
  METHOD do_mod_arc_restore.
    " *********************************************************************
    " Änderungslog
    " *********************************************************************
    " FT20170420 Note 1257 Archivierung: angelegt
    " --------------------------------------------------------------------*

    IF is_base-key                          <> is_base-guid
    OR is_base-instance->ms_node_data-arcid IS INITIAL.
      RETURN.
    ENDIF.
    " Nur archivierten QVen können wiederhergestellt werden

    DATA(lr_base) = mo_model->get_base_ref( is_base ).
    IF lr_base IS NOT BOUND.
      mx->do_handle_node_info_insuff( ).
    ENDIF.

    mo_model->do_arc_restore( lr_base ).
  ENDMETHOD.

  METHOD on_fcode.
    " *********************************************************************
    " Änderungslog
    " *********************************************************************
    " FT20170420 Note 1257 Archvierung: angelegt
    " --------------------------------------------------------------------*

    super->on_fcode( EXPORTING iv_action  = iv_action
                     IMPORTING ev_changed = ev_changed ).

    IF abap_true = is_fcode_excluded( iv_action ).
      " Der Funktionscode ist laut Profil nicht erlaubt.
      mo_tools->do_breakpoint( ).
      RETURN.
    ENDIF.

    CASE iv_action.

      WHEN mc->action_arc_restore.
        do_mod_arc_restore( ms_active-base ).
    ENDCASE.
  ENDMETHOD.

  METHOD set_active.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " FT20170421 Note 1257 Archvierung
    " Überdefiniert für den Aufruf lo_cust->set_active_arcid
    " --------------------------------------------------------------------*

    IF is_base-instance IS BOUND.

      DATA(lo_cust) = CAST /sct/qp_cl_qv_cust_service_arc( mo_cust ).
      lo_cust->set_active( iv_arcsid = is_base-instance->ms_node_data-arcsid ).

    ENDIF.

    " SUPER aufrufen
    super->set_active( iv_gui_typ    = iv_gui_typ
                       iv_workmode   = iv_workmode
                       iv_screen     = iv_screen
                       iv_profile    = iv_profile
                       is_base       = is_base
                       iv_action     = iv_action
                       iv_clear_base = iv_clear_base ).
  ENDMETHOD.
ENDCLASS.
