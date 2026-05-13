CLASS /sct/qp_cl_arc DEFINITION
  PUBLIC
  INHERITING FROM /sct/qp_cl_gts
  CREATE PUBLIC .

  PUBLIC SECTION.
    TYPE-POOLS icons .

    INTERFACES /sct/qp_if_arc .

    CLASS-DATA mv_unit_test TYPE abap_bool .

    CLASS-METHODS get_instance
      RETURNING
        VALUE(ro_arc_service) TYPE REF TO /sct/qp_if_arc
      RAISING
        /sct/qp_cx_error .
    METHODS constructor
      RAISING
        /sct/qp_cx_error .
protected section.

    "! <p class="shorttext synchronized" lang="de">Raise Konditionen in die ARC Nachrichtentabelle einfuegen</p>
  methods DO_ADD_EXCEPTION_RETURN
    importing
      !IO_ERROR type ref to /SCT/QP_CX_ERROR
      !IS_SELECT type /SCT/QP_S_DATA_SELECT optional
    changing
      !CT_ARC_RETURN type /SCT/QP_T_ARC_RETURN .
    "! <p class="shorttext synchronized" lang="de">Nachrichten in die ARC Nachrichtentabelle einfuegen</p>
  methods DO_ADD_RETURN
    importing
      !IT_RETURN type BAPIRET2_T
      !IS_SELECT type /SCT/QP_S_DATA_SELECT
    changing
      !CT_ARC_RETURN type /SCT/QP_T_ARC_RETURN .
  methods DO_OPEN
    importing
      !IS_ARCNODE type /SCT/QP_ARCNODE
      !IV_ARC_ACTION type /SCT/QP_ARC_ACTION
      !IV_TEST_MODE type ABAP_BOOL optional
      !IV_PROTOCOL_OUTPUT type ARCH_OBJ_PROT_OUTPUT_2 default /SCT/QP_CL_CONST=>ARC_PROTOCOL_OUTPUT_NONE
    returning
      value(RO_ARCTYPE) type ref to /SCT/QP_IF_ARC_TYPE
    raising
      /SCT/QP_CX_ERROR .
    "! Also create and return an ARCTYPE instance.
  methods DO_OPEN_FOR_DELETE
    importing
      !IV_TEST_MODE type ABAP_BOOL optional
      !IV_PROTOCOL_OUTPUT type ARCH_OBJ_PROT_OUTPUT_2 default /SCT/QP_CL_CONST=>ARC_PROTOCOL_OUTPUT_NONE
    exporting
      !ET_OBJECT_IDS type /SCT/QP_IF_ARC_TYPE=>T_OBJECT_ID
    returning
      value(RO_ARCTYPE) type ref to /SCT/QP_IF_ARC_TYPE
    raising
      /SCT/QP_CX_ERROR .
    "! <p class="shorttext synchronized" lang="de">Verwendungsnachweis für eine Spezifikation mit seinen Unterk</p>
    "! Wenn bei der Verwendung auch mit Löschvormerkung gesetzt werden sollen, dann gilt dieser Knoten als nicht verwendet.
  methods IS_USED
    importing
      !IS_SELECT type /SCT/QP_S_DATA_SELECT
      !IT_SELECT type /SCT/QP_T_DATA_SELECT
      !IV_CHECK_ELEMENT_VALUE type ABAP_BOOL optional
    changing
      !CT_ARC_RETURN type /SCT/QP_T_ARC_RETURN
    returning
      value(RV_USED) type BOOLEAN
    raising
      /SCT/QP_CX_ERROR .
    "! <p class="shorttext synchronized" lang="de">Setzt den Feldkatalog für die Asugabe in abhängigkeit der Ar</p>
  methods SET_FIELDCAT
    importing
      !IV_ARC_ACTION type /SCT/QP_ARC_ACTION
    returning
      value(RT_FIELDCAT) type SLIS_T_FIELDCAT_ALV .
    "! <p class="shorttext synchronized" lang="de">Setzt das Ausgabe Icon in Abhängigkeit vom des Nachrichtenty</p>
  methods SET_ICON
    changing
      !CS_ARC_RETURN type /SCT/QP_S_ARC_RETURN .
    "! <p class="shorttext synchronized" lang="de">Eine Nachricht erzeugen und in die Nachrichtentabelle einfue</p>
  methods SET_RETURN
    importing
      !IS_ARCNODE type /SCT/QP_ARCNODE optional
      !IS_SELECT type /SCT/QP_S_DATA_SELECT optional
      !IV_TYPE type BAPI_MTYPE optional
      !IV_ID type SYMSGID optional
      !IV_NUMBER type SYMSGNO
      !IV_MESSAGE_V1 type CSEQUENCE optional
      !IV_MESSAGE_V2 type CSEQUENCE optional
      !IV_MESSAGE_V3 type CSEQUENCE optional
      !IV_MESSAGE_V4 type CSEQUENCE optional
    changing
      !CT_ARC_RETURN type /SCT/QP_T_ARC_RETURN .
  PRIVATE SECTION.
ENDCLASS.



CLASS /SCT/QP_CL_ARC IMPLEMENTATION.


  METHOD /sct/qp_if_arc~change_arcid.

    IF is_arc-arcid IS INITIAL.
      RAISE EXCEPTION TYPE /sct/qp_cx_error
        EXPORTING
          textid = /sct/qp_cx_error=>input_invalid.
    ENDIF.

    DATA(ls_arc) = VALUE /sct/qp_arc( ).

    SELECT SINGLE * FROM /sct/qp_arc INTO ls_arc WHERE arcid = is_arc-arcid.
    IF sy-subrc <> 0.
      RAISE RESUMABLE EXCEPTION TYPE /sct/qp_cx_error
        EXPORTING
          textid = /sct/qp_cx_error=>arc_arcid_not_found
          arcid  = is_arc-arcid.
    ENDIF.

    IF is_arc-arcdescr IS NOT INITIAL.
      ls_arc-arcdescr = is_arc-arcdescr.
    ENDIF.

    IF is_arc-rfcdest IS NOT INITIAL.
      ls_arc-rfcdest = is_arc-rfcdest.
    ENDIF.

    IF is_arc-filedir IS NOT INITIAL.
      ls_arc-filedir = is_arc-filedir.
    ENDIF.

    mo_tools->set_verwaltungsdaten( CHANGING cs_struc_any = ls_arc ).

    MODIFY /sct/qp_arc FROM ls_arc.
    COMMIT WORK AND WAIT.

  ENDMETHOD.


  METHOD /sct/qp_if_arc~create_arcid.
* FT20260428 NOTE-3722 : Verwaltungsdaten (create) werden bei Änderungen überschrieben

    IF is_arc-arcid IS INITIAL OR is_arc-arctype IS INITIAL.
      RAISE EXCEPTION TYPE /sct/qp_cx_error
        EXPORTING
          textid = /sct/qp_cx_error=>input_invalid.
    ENDIF.

    DATA(ls_arc) = VALUE /sct/qp_arc( ).

    SELECT SINGLE * FROM /sct/qp_arc INTO ls_arc WHERE arcid = is_arc-arcid.
    IF sy-subrc = 0.
      RAISE RESUMABLE EXCEPTION TYPE /sct/qp_cx_error
        EXPORTING
          textid = /sct/qp_cx_error=>arc_arcid_existing
          arcid  = is_arc-arcid.
    ENDIF.

*    ls_arc = is_arc.      " FT20260428 NOTE-3722
    ls_arc-data = is_arc-data.

    mo_tools->set_verwaltungsdaten( CHANGING cs_struc_any = ls_arc ).

    MODIFY /sct/qp_arc FROM ls_arc.
    COMMIT WORK AND WAIT.

  ENDMETHOD.


  METHOD /sct/qp_if_arc~delete.
*--------------------------------------------------------------------*
* Änderungslog
*--------------------------------------------------------------------*
* AD, 2024.06.24, NOTE-3548
* Export Parameter
*--------------------------------------------------------------------*

    "Clear export parameters
    CLEAR: et_arc_return.

**   Only allowed for standard archive
*    DATA(ls_arc) = VALUE /sct/qp_arc( ).
*    SELECT SINGLE *
*      FROM /sct/qp_arc
*      INTO ls_arc
*      WHERE arcid = mc->arcid_standard.

    TRY.
*       Decide whether to run in pure selection mode (background processing possible)
*       or in job execution mode (only executable via SARA delete action)
        IF it_select IS NOT INITIAL.

          DATA(lt_select) = it_select.

        ELSE.

          DATA(lv_job_mode) = abap_true.

          me->do_open_for_delete(
            EXPORTING
              iv_test_mode       = iv_test_mode
              iv_protocol_output = iv_protocol_output
            IMPORTING
              et_object_ids      = DATA(lt_object_ids)
            RECEIVING
              ro_arctype         = DATA(lo_arctype) ).

          lt_select = VALUE #( FOR <guid> IN lt_object_ids ( guid = <guid> ) ).

        ENDIF.

        LOOP AT lt_select INTO DATA(ls_sel).

          TRY.

              DATA(ls_arcnode) = VALUE /sct/qp_arcnode( ).  "MD170502
              SELECT SINGLE * FROM /sct/qp_arcnode INTO ls_arcnode WHERE arcid = mc->arcid_standard AND guid = ls_sel-guid.
              IF sy-subrc <> 0.
                RAISE EXCEPTION TYPE /sct/qp_cx_error
                  EXPORTING
                    textid = /sct/qp_cx_error=>arc_arcnode_not_found
                    guid   = ls_sel-guid
                    arcid  = mc->arcid_standard.
              ENDIF.
              MOVE-CORRESPONDING ls_arcnode TO ls_sel.

              IF iv_check_use = abap_true AND is_used( EXPORTING is_select = ls_sel
                                                                 it_select = lt_select
                                                                 iv_check_element_value = abap_true
                                                       CHANGING  ct_arc_return = et_arc_return ) = abap_true.
                CONTINUE.
              ENDIF.

*             Open single file if not already opened for job deletion
              IF lv_job_mode = abap_false.
                lo_arctype = me->do_open(
                  is_arcnode         = ls_arcnode
                  iv_arc_action      = mc->arc_action-delete
                  iv_test_mode       = iv_test_mode
                  iv_protocol_output = iv_protocol_output ).
              ENDIF.

              mo_bus->delete( EXPORTING is_header =  VALUE #( guid = ls_sel-guid vart = ls_sel-vart )
                                         IMPORTING et_return =  DATA(lt_return)
                                                   ev_error  =  DATA(lv_error) ).

              do_add_return( EXPORTING it_return     = lt_return
                                       is_select     = ls_sel
                             CHANGING  ct_arc_return = et_arc_return ).

              IF lv_error = abap_false AND iv_test_mode = abap_false.
                mo_bus->save( ).
              ENDIF.

              mo_bus->free( iv_root_guid = ls_sel-guid ).  "MD171215 N1687

*             Überprüfung, ob Datensatz tatsächlich gelöscht ist.
              DATA(lv_guid) = VALUE /sct/qp_guid( ).
              IF iv_test_mode = abap_false.

                SELECT SINGLE guid INTO lv_guid FROM /sct/qp_status WHERE guid = ls_sel-guid.
                IF lv_guid IS NOT INITIAL.
                  set_return( EXPORTING is_select     = ls_sel
                                        iv_type       = mc->msgtype_e
                                        iv_number     = mc->msgno_313
                                        iv_message_v1 = CONV string( ls_sel-vnr )
                                        iv_message_v2 = CONV string( ls_sel-vvs )
                                        iv_message_v3 = ls_sel-vname
                              CHANGING  ct_arc_return = et_arc_return ).
                ENDIF.
              ENDIF.

              IF lv_guid IS INITIAL.
                set_return( EXPORTING is_select     = ls_sel
                                      iv_type       = mc->msgtype_s
                                      iv_number     = mc->msgno_315
                                      iv_message_v1 = CONV string( ls_sel-vnr )
                                      iv_message_v2 = CONV string( ls_sel-vvs )
                                      iv_message_v3 = ls_sel-vname
                            CHANGING  ct_arc_return = et_arc_return ).
              ENDIF.

            CATCH /sct/qp_cx_error INTO DATA(lo_error).
              do_add_exception_return( EXPORTING io_error      = lo_error
                                       CHANGING  ct_arc_return = et_arc_return ).
          ENDTRY.

        ENDLOOP.

      CATCH /sct/qp_cx_error INTO lo_error.
        do_add_exception_return( EXPORTING io_error      = lo_error
                                 CHANGING  ct_arc_return = et_arc_return ).
    ENDTRY.

*   Save protocol messages to ADK and close file handle
    TRY.
        lo_arctype->add_message( it_arc_return = et_arc_return ).
        lo_arctype->close( ).

      CATCH /sct/qp_cx_error INTO lo_error.
        do_add_exception_return( EXPORTING io_error      = lo_error
                                 CHANGING  ct_arc_return = et_arc_return ).
    ENDTRY.

  ENDMETHOD.


  METHOD /sct/qp_if_arc~get_arcid.

    IF iv_arcid IS INITIAL.
      RAISE EXCEPTION TYPE /sct/qp_cx_error
        EXPORTING
          textid = /sct/qp_cx_error=>input_invalid.
    ENDIF.

    SELECT SINGLE * FROM /sct/qp_arc INTO rs_arc WHERE arcid = iv_arcid.

  ENDMETHOD.


  METHOD /sct/qp_if_arc~mark_for_deletion.
*    DATA: lt_change TYPE /sct/qp_t_qvc_data.
*    DATA: lv_zqlo   TYPE /sct/qp_izqlo.

    TRY.

        "MD170502 Keine ARCTYPE Nutzung hier
*        DATA(lo_arctype) = me->do_open( is_arcnode        = VALUE #( arcid = mc->arcid_standard )
*                                        iv_arc_action = mc->arc_action-mark_for_deletion
*                                        iv_test_mode  = iv_test_mode
*                                        iv_protocol_output = iv_protocol_output
*                                         ).

        LOOP AT it_select ASSIGNING FIELD-SYMBOL(<fs_sel>).

          IF iv_check_use = abap_true AND  is_used( EXPORTING is_select = <fs_sel>
                                                              it_select = it_select
                                                              iv_check_element_value = abap_true
                                                    CHANGING  ct_arc_return = et_arc_return )
                                                   = abap_true.
            CONTINUE.
          ENDIF.


*---- Lösung mit BUS Methoden nicht sinnvoll:
* 1. Performance: 2. Der Hauptstatus nach dem Restore geht verloren
*          mo_bus->change( EXPORTING is_header =  VALUE #( guid = <fs_sel>-guid )   " Schlüssel zum Kopf der Vorschrift
*                                     IMPORTING et_return =  DATA(lt_return)        " Returntabelle
*                                               ev_error  =  DATA(lv_error)         " Fehler aufgetreten
*                                               es_base   = DATA(ls_base_header) ). " Daten Vorschriften Hierarchie
*          IF lv_error = abap_true.
*            do_add_return( EXPORTING it_return     = lt_return
*                                  is_select     = <fs_sel>
*                        CHANGING  ct_arc_return = et_arc_return ).
*          ELSE.
*
*            lt_change = VALUE #( ( guid = <fs_sel>-guid ) ).
*            mo_bus->activity( EXPORTING is_header   =  VALUE #( guid = <fs_sel>-guid )  " Schlüssel zum Kopf der Vorschrift
*                                                   iv_activity =  mc->activity_delete  " Vorgang
*                                                   it_change   =  lt_change    " Beinhaltet die zu ändernden Daten
*                                         IMPORTING et_return   =  lt_return     " Returntabelle
*                                                   ev_error    =  lv_error ).   " Fehler aufgetreten
*
*            do_add_return( EXPORTING it_return     = lt_return
*                                  is_select     = <fs_sel>
*                        CHANGING  ct_arc_return = et_arc_return ).
*            IF lv_error IS INITIAL AND iv_test_mode IS INITIAL.  "nur Sichern wenn kein Fehler aufgetreten ist, oder nicht im TestModus
*              mo_bus->save( ).
*            ENDIF.
*          ENDIF.
*          mo_bus->free( ).
*          CLEAR: lv_zqlo.
*          IF iv_test_mode IS INITIAL.
*
*            SELECT SINGLE izqlo INTO lv_zqlo FROM /sct/qp_status WHERE guid = <fs_sel>-guid.
*            IF lv_zqlo IS INITIAL.
*              set_return( EXPORTING is_select     = <fs_sel>
*                                    iv_type       = mc->msgtype_e
*                                    iv_number     = mc->msgno_310
*                                    iv_message_v1 = CONV string( <fs_sel>-vnr )
*                                    iv_message_v2 = CONV string( <fs_sel>-vvs )
*                                    iv_message_v3 = <fs_sel>-vname
*                          CHANGING  ct_arc_return = et_arc_return  ).
*            ENDIF.
*          ENDIF.


          UPDATE /sct/qp_status SET izqlo = abap_true WHERE guid = <fs_sel>-guid. "#EC CI_IMUD_NESTED

          set_return( EXPORTING is_select     = <fs_sel>
                                iv_type       = mc->msgtype_s
                                iv_number     = mc->msgno_312
                                iv_message_v1 = CONV string( <fs_sel>-vnr )
                                iv_message_v2 = CONV string( <fs_sel>-vvs )
                                iv_message_v3 = <fs_sel>-vname
                      CHANGING  ct_arc_return = et_arc_return ).


        ENDLOOP.

        IF iv_test_mode = abap_true.
          ROLLBACK WORK.
        ELSE.
          COMMIT WORK.
        ENDIF.
        "MD170502 Keine ARCTYPE Nutzung hier
*        lo_arctype->add_message( it_arc_return = et_arc_return ).
*        lo_arctype->close( ).

      CATCH /sct/qp_cx_error INTO DATA(lo_error).
        CLEAR et_arc_return.  "Positive Nachrichten wieder löschen
        do_add_exception_return( EXPORTING io_error      = lo_error
                                 CHANGING  ct_arc_return = et_arc_return ).
    ENDTRY.
  ENDMETHOD.


  METHOD /sct/qp_if_arc~output_messages.
*--------------------------------------------------------------------*
* Änderungslog
*--------------------------------------------------------------------*
* AD, 2024.06.27, NOTE-3548
* SY-SUBRC behandeln
*--------------------------------------------------------------------*

    DATA lt_out TYPE /sct/qp_t_arc_return.

* Die Ausgabetabelle muss geändert werden können. Vorgabe des Bausteins
    lt_out = it_arc_return.

    DATA(lt_fieldcat) = set_fieldcat( iv_arc_action ).

    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
      EXPORTING
        it_fieldcat   = lt_fieldcat
      TABLES
        t_outtab      = lt_out
      EXCEPTIONS
        program_error = 1
        OTHERS        = 2.

    IF sy-subrc <> 0.
      mx->do_handle_internal_errorx( ).
    ENDIF.
  ENDMETHOD.


  METHOD /sct/qp_if_arc~read.
*--------------------------------------------------------------------*
* Änderungslog
*--------------------------------------------------------------------*
* MD, 2018.07.11: N1884 Performance-Optimierung / Ausnahmebehandlung
*--------------------------------------------------------------------*

    CLEAR: et_qvc_data.

    DATA(lt_arcnode) = it_arcnode.
    SORT lt_arcnode BY arcfid.

    LOOP AT lt_arcnode ASSIGNING FIELD-SYMBOL(<fg_arcnode_fid>)   "MD180711 N1884
      GROUP BY ( arcfid   = <fg_arcnode_fid>-arcfid
                 filename = <fg_arcnode_fid>-filename
                 arctype  = <fg_arcnode_fid>-arctype ).
      TRY.

          DATA(lo_arctype) = me->do_open( is_arcnode    = CORRESPONDING #( <fg_arcnode_fid> )
                                          iv_arc_action = COND #( WHEN iv_for_restore = abap_false
                                            THEN mc->arc_action-read ELSE mc->arc_action-restore )
                                          iv_test_mode  = iv_test_mode
                                          iv_protocol_output = iv_protocol_output ).

          LOOP AT GROUP <fg_arcnode_fid> ASSIGNING FIELD-SYMBOL(<fs_arcnode>).  "MD180711 N1884
            TRY.

                lo_arctype->read(
                  EXPORTING
                    is_arcnode  = <fs_arcnode>
                  IMPORTING
                    es_db_data  = DATA(ls_db_data)
                    et_qvc_data = DATA(lt_qvc_data) ).

                IF lt_qvc_data IS INITIAL.
                  mo_data->map_data_db_to_qvc( EXPORTING is_db_data         = ls_db_data
                                               IMPORTING et_qvc_data_unsort = lt_qvc_data ).
                ENDIF.
                LOOP AT lt_qvc_data ASSIGNING FIELD-SYMBOL(<fs_qvc>). "#EC CI_NESTED
                  <fs_qvc>-arcid  = <fs_arcnode>-arcid.
                  <fs_qvc>-arcsid = <fs_arcnode>-arcsid.
                ENDLOOP.
                APPEND LINES OF lt_qvc_data TO et_qvc_data.
                CLEAR ls_db_data.
                CLEAR lt_qvc_data.

              CATCH /sct/qp_cx_error INTO DATA(lo_error).   "MD180711 N1884
                do_add_exception_return( EXPORTING io_error      = lo_error
                                                   is_select     = CORRESPONDING #( <fs_arcnode> )
                                         CHANGING  ct_arc_return = et_arc_return ).
            ENDTRY.
          ENDLOOP.

          lo_arctype->close( ).

        CATCH /sct/qp_cx_error INTO lo_error.   "MD180711 N1884
          do_add_exception_return( EXPORTING io_error      = lo_error
                                   CHANGING  ct_arc_return = et_arc_return ).
      ENDTRY.

    ENDLOOP.

  ENDMETHOD.


  METHOD /sct/qp_if_arc~read_customizing.

    DATA(ls_arcnode) = VALUE /sct/qp_arcnode( ).

    TRY.
*       Read first ARCNODE for given session from ARCNODE table to receive the ARCTYPE and ARCID
        SELECT SINGLE *
          FROM /sct/qp_arcnode
          INTO ls_arcnode
          WHERE arcsid = iv_arcsid.                     "#EC CI_NOFIELD
        IF sy-subrc <> 0.
          RAISE EXCEPTION TYPE /sct/qp_cx_error
            EXPORTING
              textid = /sct/qp_cx_error=>arc_session_not_found
              arcsid = iv_arcsid.
        ENDIF.

        DATA(lo_arctype) = me->do_open( is_arcnode    = ls_arcnode
                                        iv_arc_action = mc->arc_action-read ).

        lo_arctype->read_customizing( IMPORTING es_cust_db = es_cust_db ).

      CATCH /sct/qp_cx_error INTO DATA(lx).
        do_add_exception_return( EXPORTING io_error      = lx
                                 CHANGING  ct_arc_return = et_arc_return ).
    ENDTRY.

  ENDMETHOD.


  METHOD /sct/qp_if_arc~restore.
*--------------------------------------------------------------------*
* Änderungslog
*--------------------------------------------------------------------*
* MD, 2018.07.11: N1884 Performance-Optimierung / Ausnahmebehandlung
* MD, 2018.07.26: N1885 Einträge nach aktuellem ARCNODE filtern
*--------------------------------------------------------------------*
* AD, 2019.02.08, NOTE 2028 LASTUPDATE setzen
*--------------------------------------------------------------------*
* MD, 2020.06.23: N2479 Zusätzliche Tabellen archivieren
    "--------------------------------------------------------------------"
    " AD, 2021.03.03, NOTE 3108
    " Folgeprozesse
    "--------------------------------------------------------------------"

    DATA(lo_progress) = /sct/qp_cl_progress=>get_instance( ).

    DATA(lt_arcnode) = it_arcnode.

    SORT lt_arcnode BY arcfid.

    lo_progress->set_total( lines( it_arcnode ) ).
    lo_progress->set_counter( abap_true ).
    lo_progress->set_indicator_interval( 1 ).

    LOOP AT lt_arcnode ASSIGNING FIELD-SYMBOL(<fg_arcnode_fid>)   "MD180711 N1884
      GROUP BY ( arcfid   = <fg_arcnode_fid>-arcfid
                 filename = <fg_arcnode_fid>-filename
                 arctype  = <fg_arcnode_fid>-arctype ).
      TRY.

          IF <fg_arcnode_fid>-arcfid IS NOT INITIAL.
            lo_progress->update_indicator( iv_object = |OPEN FILE: { <fg_arcnode_fid>-arcfid }| ).
          ELSEIF <fg_arcnode_fid>-filename IS NOT INITIAL.  "MD180726 INS
            lo_progress->update_indicator( iv_object = |OPEN FILE: { <fg_arcnode_fid>-filename }| ).
          ENDIF.

          DATA(lo_arctype) = me->do_open( is_arcnode         = CORRESPONDING #( <fg_arcnode_fid> )   "MD180711 N1884
                                          iv_arc_action      = mc->arc_action-restore
                                          iv_test_mode       = iv_test_mode
                                          iv_protocol_output = iv_protocol_output ).

          LOOP AT GROUP <fg_arcnode_fid> ASSIGNING FIELD-SYMBOL(<fs_arcnode>).  "MD180711 N1884
            TRY.

                lo_progress->increment( ).
                lo_progress->update_indicator( iv_object = |RESTORE: { <fs_arcnode>-vart } : { <fs_arcnode>-vname }| ).

                lo_arctype->read( EXPORTING is_arcnode  = <fs_arcnode>
                                  IMPORTING es_db_data  = DATA(ls_db_data_all)    "MD180726 N1885 CHG
                                            "et_qvc_data = DATA(lt_qvc_data)
                                             ).

                "MD180711 N1885 DEL Löschung von irrelevanten Einträgen ersetzt durch Filterung (siehe unten)

*               Weil Test Injections in globalen Testklassen nicht funktionieren... muss ein Attribut herhalten
                IF mv_unit_test = abap_true.
                  mo_data->do_delete_node_hierarchy( iv_guid = <fs_arcnode>-guid ).
                ENDIF.

*               MD, 2018.07.26: N1885, BoI
*               Einträge ggf. nach aktuellem ARCNODE und dessen Relationen filtern (notwendig
*               bspw. für Dateiarchivierung, da von READ immer alle Einträge der Datei eingelesen werden
                DATA(ls_db_data) = VALUE /sct/qp_s_db_data( ).
                LOOP AT ls_db_data_all-node ASSIGNING FIELD-SYMBOL(<fs_node>) WHERE guid = <fs_arcnode>-guid ##PRIMKEY[GUID]. "#EC CI_NESTED

                  DATA(lt_node) = VALUE /sct/qp_t_node( FOR <node> IN ls_db_data_all-node WHERE ( oguid = <fs_node>-guid ) ( <node> ) ) ##PRIMKEY[OGUID].

                  ls_db_data-node = VALUE #( BASE ls_db_data-node FOR <node> IN lt_node ( <node> ) ).

                  LOOP AT lt_node ASSIGNING FIELD-SYMBOL(<fs_node_sub>). "#EC CI_NESTED

                    ls_db_data-noderel = VALUE #( BASE ls_db_data-noderel
                        FOR <noderel> IN ls_db_data_all-noderel
                        WHERE ( pguid = <fs_node_sub>-guid ) ( <noderel> ) ) ##PRIMKEY[PGUID].

                    ls_db_data-nodet      = VALUE #( BASE ls_db_data-nodet      FOR <nodet> IN ls_db_data_all-nodet
                                                                                WHERE ( guid = <fs_node_sub>-guid ) ( <nodet> ) ) ##PRIMKEY[GUID].
                    ls_db_data-status     = VALUE #( BASE ls_db_data-status     FOR <status> IN ls_db_data_all-status
                                                                                WHERE ( guid = <fs_node_sub>-guid ) ( <status> ) ) ##PRIMKEY[GUID].
                    ls_db_data-ana        = VALUE #( BASE ls_db_data-ana        FOR <ana> IN ls_db_data_all-ana
                                                                                WHERE ( guid = <fs_node_sub>-guid ) ( <ana> ) ) ##PRIMKEY[GUID].
                    ls_db_data-bds        = VALUE #( BASE ls_db_data-bds        FOR <bds> IN ls_db_data_all-bds
                                                                                WHERE ( guid = <fs_node_sub>-guid ) ( <bds> ) ) ##PRIMKEY[GUID].
                    ls_db_data-log        = VALUE #( BASE ls_db_data-log        FOR <log> IN ls_db_data_all-log
                                                                                WHERE ( guid = <fs_node_sub>-guid ) ( <log> ) ) ##PRIMKEY[GUID].
                    ls_db_data-pmk        = VALUE #( BASE ls_db_data-pmk        FOR <pmk> IN ls_db_data_all-pmk
                                                                                WHERE ( guid = <fs_node_sub>-guid ) ( <pmk> ) ) ##PRIMKEY[GUID].
                    ls_db_data-stx        = VALUE #( BASE ls_db_data-stx        FOR <stx> IN ls_db_data_all-stx
                                                                                WHERE ( guid = <fs_node_sub>-guid ) ( <stx> ) ) ##PRIMKEY[GUID].
                    ls_db_data-val        = VALUE #( BASE ls_db_data-val        FOR <val> IN ls_db_data_all-val USING KEY goe
                                                                                WHERE ( guid = <fs_node_sub>-guid ) ( <val> ) ) ##PRIMKEY[GUID].
                    ls_db_data-valt       = VALUE #( BASE ls_db_data-valt       FOR <valt> IN ls_db_data_all-valt USING KEY gore
                                                                                WHERE ( guid = <fs_node_sub>-guid ) ( <valt> ) ).
                    ls_db_data-text       = VALUE #( BASE ls_db_data-text       FOR <text> IN ls_db_data_all-text
                                                                                WHERE ( guid = <fs_node_sub>-guid ) ( <text> ) ) ##PRIMKEY[GUID].
                    " MD, 2020.06.23: N2479, BoI

                    ls_db_data-num        = VALUE #( BASE ls_db_data-num        FOR <num> IN ls_db_data_all-num USING KEY goe
                                                                                WHERE ( guid = <fs_node_sub>-guid ) ( <num> ) ).
                    ls_db_data-cdhdr      = VALUE #( BASE ls_db_data-cdhdr      FOR <cdhdr> IN ls_db_data_all-cdhdr
                                                                                WHERE ( objectid CP |{ <fs_node_sub>-guid }*| ) ( <cdhdr> ) ).
                    ls_db_data-cdpos      = VALUE #( BASE ls_db_data-cdpos      FOR <cdpos> IN ls_db_data_all-cdpos
                                                                                WHERE ( objectid CP |{ <fs_node_sub>-guid }*| ) ( <cdpos> ) ).
                    ls_db_data-cdpos_uid  = VALUE #( BASE ls_db_data-cdpos_uid  FOR <cdpos_uid> IN ls_db_data_all-cdpos_uid
                                                                                WHERE ( objectid CP |{ <fs_node_sub>-guid }*| ) ( <cdpos_uid> ) ).
                    " MD, 2020.06.23: N2479, EoI

                  ENDLOOP.

                ENDLOOP.
*               MD, 2018.07.26: N1885, EoI

                "AD, 2023.04.11, NOTE-3372, BoC
                "AD, 2019.02.08, NOTE 2028, BoI
                CALL METHOD mo_tools->get_utc_time
                  IMPORTING
                    ev_timestamp_long = DATA(lv_lastupdate).

                "LASTUPDATE setzen
                LOOP AT ls_db_data-node ASSIGNING FIELD-SYMBOL(<ls_node>). "#EC CI_NESTED
                  <ls_node>-lastupdate = lv_lastupdate.
                ENDLOOP.
                "AD, 2019.02.08, NOTE 2028, EoI
                "AD, 2023.04.11, NOTE-3372, EoC

                CALL METHOD mo_data->save
                  EXPORTING
                    is_db_data = ls_db_data.

                set_return( EXPORTING is_select     = CORRESPONDING #( <fs_arcnode> )
                                      iv_type       = mc->msgtype_s
                                      iv_number     = mc->msgno_330
                                      iv_message_v1 = CONV string( <fs_arcnode>-vnr )
                                      iv_message_v2 = CONV string( <fs_arcnode>-vvs )
                                      iv_message_v3 = <fs_arcnode>-vname
                            CHANGING  ct_arc_return = et_arc_return  ).

                "CLEAR lt_qvc_data.

              CATCH /sct/qp_cx_error INTO DATA(lo_error).   "MD180711 N1884
                do_add_exception_return( EXPORTING io_error      = lo_error
                                         CHANGING  ct_arc_return = et_arc_return ).
            ENDTRY.

          ENDLOOP.

          IF iv_test_mode = abap_true.  "MD170502 Auch hier COMMIT oder ROLLBACK anhand des Modus
            ROLLBACK WORK.                             "#EC CI_ROLLBACK
          ELSE.
            COMMIT WORK AND WAIT.
          ENDIF.
          lo_arctype->close( ).

        CATCH /sct/qp_cx_error INTO lo_error.   "MD180711 N1884
          do_add_exception_return( EXPORTING io_error      = lo_error
                                   CHANGING  ct_arc_return = et_arc_return ).
      ENDTRY.
    ENDLOOP.

  ENDMETHOD.


  METHOD /sct/qp_if_arc~write.
*--------------------------------------------------------------------*
* Änderungslog
*--------------------------------------------------------------------*
* MD, 2018.06.08: N1859 Ausnahme, wenn ARCID auf DB nicht vorhanden
* MD, 2018.07.11: N1886 Customizing schreiben optional
* MD, 2020.07.06: N2496 Aufbereitung NODET korrigiert
*--------------------------------------------------------------------*
* AD, 2024.07.10, NOTE-3548
* COMMIT nicht steuerbar
*--------------------------------------------------------------------*

    " Write given QVs into the archive and create ARCNODEs while doing that

    DATA: lt_arcnodet TYPE STANDARD TABLE OF /sct/qp_arcnodet,
          ls_admin    TYPE /sct/qp_s_admin,
          ls_arc      TYPE /sct/qp_arc.

    TRY.
        SELECT SINGLE *
          FROM /sct/qp_arc
          INTO ls_arc
          WHERE arcid = iv_arcid.

        " MD, 2018.06.08: N1859, BoI
        IF sy-subrc <> 0.
          RAISE EXCEPTION TYPE /sct/qp_cx_error
            EXPORTING
              textid = /sct/qp_cx_error=>arc_arcid_not_found.
        ENDIF.
        " MD, 2018.06.08: N1859, EoI

        DATA(lo_arctype) = me->do_open( EXPORTING is_arcnode         = CORRESPONDING #( ls_arc )
                                                  iv_arc_action      = mc->arc_action-write
                                                  iv_test_mode       = iv_test_mode
                                                  iv_protocol_output = iv_protocol_output ).

        " Save given customizing state one time for the session just performed
        IF iv_incl_cust = abap_true.    "MD180711 N1886
          mo_cust->get_cust( IMPORTING es_cust_db = DATA(ls_cust) ).
          lo_arctype->write_customizing( ls_cust ).
        ENDIF.

        " Write given QVs into the archive and create ARCNODEs while doing that
        LOOP AT it_select ASSIGNING FIELD-SYMBOL(<fs_sel>).
          CLEAR: lt_arcnodet, ls_admin.
          TRY.
              mo_data->get_data(
                EXPORTING
                  is_input    = VALUE #( guid             = <fs_sel>-guid
                                         sel_tables       = mc->select_tables-arc
                                         read_db          = abap_true
                                         read_hierarchy   = abap_true )
                IMPORTING
                  es_db_data  = DATA(ls_db_data)
                  et_qvc_data = DATA(lt_qvc_data) ).

              IF lt_qvc_data IS INITIAL.

                set_return( EXPORTING is_select     = <fs_sel>
                                      iv_type       = mc->msgtype_e
                                      iv_number     = mc->msgno_328
                                      iv_message_v1 = CONV string( <fs_sel>-vnr )
                                      iv_message_v2 = CONV string( <fs_sel>-vvs )
                                      iv_message_v3 = <fs_sel>-vname
                            CHANGING  ct_arc_return = et_arc_return ).
                CONTINUE.
              ENDIF.

              " Weil Test Injections in globalen Testklassen nicht funktionieren... muss ein Attribut herhalten
              IF mv_unit_test = abap_true.
                mo_data->do_delete_node_hierarchy( iv_guid = <fs_sel>-guid ).
              ENDIF.

              " Löschkennzeichnung zurücknehmen.
              READ TABLE ls_db_data-status ASSIGNING FIELD-SYMBOL(<fs_db_status>) WITH KEY guid = <fs_sel>-guid ##PRIMKEY[GUID].
              IF sy-subrc = 0.
                <fs_db_status>-izqlo = abap_false. "NS, 2023.05.12, NOTE-3394 statt ZQLO soll IZQLO gecleared werden.
              ENDIF.
              READ TABLE lt_qvc_data ASSIGNING FIELD-SYMBOL(<fs_qvc>) WITH KEY guid = <fs_sel>-guid.
              IF sy-subrc = 0.
                <fs_qvc>-status-izqlo = abap_false. "NS, 2023.05.12, NOTE-3394 statt ZQLO soll IZQLO gecleared werden.
              ENDIF.

              lo_arctype->write( EXPORTING is_root_select = <fs_sel>
                                           is_db_data     = ls_db_data
                                           it_qvc_data    = lt_qvc_data
                                           iv_commit_work = iv_commit_work
                                 IMPORTING es_arcnode     = DATA(ls_arcnode) ).

              "-------------------------------------------------------------------------
              " Archvierungsdaten aufbereiten
              "-------------------------------------------------------------------------
              ASSIGN lt_qvc_data[ guid = <fs_sel>-guid ] TO FIELD-SYMBOL(<fs_root>).
              MOVE-CORRESPONDING <fs_root> TO ls_arcnode-info.
              MOVE <fs_root>-status-istat TO ls_arcnode-istat.
              MOVE sy-mandt               TO ls_arcnode-mandt.
              mo_tools->set_verwaltungsdaten( CHANGING cs_struc_any = ls_admin ).
              ls_arcnode-archived_date = ls_admin-erdat.
              ls_arcnode-archived_time = ls_admin-ertime.
              ls_arcnode-archived_user = ls_admin-ername.

              " MD, 2020.07.06: N2496, BoC
              MOVE-CORRESPONDING <fs_root>-nodet TO lt_arcnodet.
              LOOP AT lt_arcnodet ASSIGNING FIELD-SYMBOL(<fs_nodet>). "#EC CI_NESTED
                <fs_nodet>-mandt = sy-mandt.
                <fs_nodet>-arcid = iv_arcid.
              ENDLOOP.
              " MD, 2020.07.06: N2496, EoC

              "-------------------------------------------------------------------------
              " Archvierungsdaten speichern
              "-------------------------------------------------------------------------
              MODIFY /sct/qp_arcnode FROM ls_arcnode. "#EC CI_IMUD_NESTED
              DELETE FROM /sct/qp_arcnodet WHERE arcid = iv_arcid AND guid = <fs_sel>-guid. "#EC CI_IMUD_NESTED
              MODIFY /sct/qp_arcnodet FROM TABLE lt_arcnodet. "#EC CI_IMUD_NESTED

              set_return(
                EXPORTING
                  is_arcnode    = ls_arcnode
                  iv_type       = mc->msgtype_s
                  iv_number     = mc->msgno_314
                  iv_message_v1 = CONV string( <fs_sel>-vnr )
                  iv_message_v2 = CONV string( <fs_sel>-vvs )
                  iv_message_v3 = <fs_sel>-vname
                CHANGING
                  ct_arc_return = et_arc_return ).

            CATCH /sct/qp_cx_error INTO DATA(lo_error).

              do_add_exception_return( EXPORTING io_error      = lo_error
                                                 is_select     = <fs_sel>
                                       CHANGING  ct_arc_return = et_arc_return ).
          ENDTRY.
        ENDLOOP.

        "-------------------------------------------------------------------------
        "   Save created ARCNODEs and perform archiving type specific saving operations
        "-------------------------------------------------------------------------
        lo_arctype->add_message( ).
        lo_arctype->close( ).

        "-------------------------------------------------------------------------
        " Admin Daten im Archiv aktualisieren
        "-------------------------------------------------------------------------
        mo_tools->set_verwaltungsdaten( CHANGING cs_struc_any = ls_arc ).
        MODIFY /sct/qp_arc FROM ls_arc.

      CATCH /sct/qp_cx_error INTO lo_error.
        CLEAR et_arc_return.  "Positive Nachrichten wieder löschen

        do_add_exception_return( EXPORTING io_error      = lo_error
                                 CHANGING  ct_arc_return = et_arc_return ).
    ENDTRY.

    IF iv_test_mode = abap_true.
      ROLLBACK WORK.                                   "#EC CI_ROLLBACK
    ELSE.
      COMMIT WORK AND WAIT.
    ENDIF.

  ENDMETHOD.


  METHOD constructor.
    super->constructor( ).

    /sct/qp_cl_factory=>get_instances( IMPORTING eo_data  = mo_data
                                                 eo_const = mc
                                                 eo_cust  = mo_cust
                                                 eo_bus   = mo_bus
                                                 eo_tools = mo_tools
                                                 eo_error = mx ).

  ENDMETHOD.


  METHOD do_add_exception_return.

*    DATA ls_arc_ret TYPE /sct/qp_s_arc_return.

    DATA(ls_return) = io_error->get_msg_bapiret( ).

    APPEND INITIAL LINE TO ct_arc_return ASSIGNING FIELD-SYMBOL(<fs_arcret>).
    MOVE-CORRESPONDING ls_return TO <fs_arcret>.
    MOVE-CORRESPONDING is_select TO <fs_arcret>.
    <fs_arcret>-type = mc->msgtype_a. "Abbruch
    set_icon( CHANGING cs_arc_return = <fs_arcret> ).

  ENDMETHOD.


  METHOD do_add_return.

    LOOP AT it_return ASSIGNING FIELD-SYMBOL(<fs_ret>).
      CHECK <fs_ret>-number <> mc->msgno_143.   "Standard erfolgsmeldung aus BUS-Methoden. Sollen nicht ausgegeben werden.

      APPEND INITIAL LINE TO ct_arc_return ASSIGNING FIELD-SYMBOL(<fs_arcret>).
      MOVE-CORRESPONDING <fs_ret> TO <fs_arcret>.
      MOVE-CORRESPONDING is_select TO <fs_arcret>.
      set_icon( CHANGING cs_arc_return = <fs_arcret> ).
    ENDLOOP.

  ENDMETHOD.


  METHOD do_open.
    "--------------------------------------------------------------------*
    " Änderungslog
    "--------------------------------------------------------------------*
    " AD, 2021.11.19, NOTE 3135
    " Set Scenario
    "--------------------------------------------------------------------*

*   When found an archive, we determine the ARCTYPE instance using the information we got from the DB
    CALL METHOD /sct/qp_cl_factory=>get_instance
      EXPORTING
        iv_classcondition = CONV #( is_arcnode-arctype )
      CHANGING
        co_instance       = ro_arctype.

    ro_arctype->open( is_arcnode         = is_arcnode
                      iv_arc_action      = iv_arc_action
                      iv_test_mode       = iv_test_mode
                      iv_protocol_output = iv_protocol_output ).

  ENDMETHOD.


  METHOD do_open_for_delete.
    "--------------------------------------------------------------------*
    " Änderungslog
    "--------------------------------------------------------------------*
    " AD, 2021.11.19, NOTE 3135
    " Set Scenario
    "--------------------------------------------------------------------*

    DATA(ls_arc) = VALUE /sct/qp_arc( ).

    SELECT SINGLE *
      FROM /sct/qp_arc
      INTO ls_arc
      WHERE arcid = mc->arcid_standard.

*   When found an archive, we determine the ARCTYPE instance using the information we got from the DB
    CALL METHOD /sct/qp_cl_factory=>get_instance
      EXPORTING
        iv_classcondition = CONV #( ls_arc-arctype )
      CHANGING
        co_instance       = ro_arctype.

    ro_arctype->open_for_delete(
      EXPORTING
        iv_test_mode       = iv_test_mode
        iv_protocol_output = iv_protocol_output
      IMPORTING
        et_object_ids      = et_object_ids ).

  ENDMETHOD.


  METHOD get_instance.
**********************************************************************
* FT20210728 Note 3135 keine Instanz-Pufferung (Scenario)
*--------------------------------------------------------------------*
    /sct/qp_cl_factory=>get_instances(
      IMPORTING
        eo_arc = ro_arc_service ).

  ENDMETHOD.


  METHOD is_used.
*--------------------------------------------------------------------*
* Änderungslog
*--------------------------------------------------------------------*
* AD, 2024.06.24, NOTE-3548
* GUID range
*--------------------------------------------------------------------*

    DATA:
    lt_node TYPE /sct/qp_t_range_guid.

    CLEAR: lt_node.

    SELECT ##TOO_MANY_ITAB_FIELDS
      'I'  AS sign,
      'EQ' AS option,
      guid AS low
      INTO CORRESPONDING FIELDS OF TABLE @lt_node
      FROM /sct/qp_node
      WHERE oguid = @is_select-guid.

    LOOP AT lt_node ASSIGNING FIELD-SYMBOL(<ls_node>).

      mo_data->where_used_list( EXPORTING iv_guid = <ls_node>-low
                                IMPORTING et_node = DATA(lt_used_nodes) ).

      LOOP AT it_select ASSIGNING FIELD-SYMBOL(<fs_sel>). "#EC CI_NESTED
        DELETE lt_used_nodes WHERE oguid = <fs_sel>-guid.
      ENDLOOP.

      IF lt_used_nodes IS NOT INITIAL.
        set_return( EXPORTING is_select     = is_select
                              iv_type       = mc->msgtype_w
                              iv_number     = mc->msgno_311
                              iv_message_v1 = CONV string( is_select-vnr )
                              iv_message_v2 = CONV string( is_select-vvs )
                    CHANGING  ct_arc_return = ct_arc_return ).
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD set_fieldcat.

    CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
      EXPORTING
        i_structure_name       = '/SCT/QP_S_ARC_RETURN' " Strukturname(Struktur, Tabelle, View)
        i_bypassing_buffer     = 'X' " Am Puffer vorbeilesen
*       i_buffer_active        =     " Spezial-Pufferung aktiv
      CHANGING
        ct_fieldcat            = rt_fieldcat " Feldkatalog mit Feldbeschreibungen
      EXCEPTIONS "#EC FB_RC
        inconsistent_interface = 1
        program_error          = 2
        OTHERS                 = 3.

    LOOP AT rt_fieldcat ASSIGNING FIELD-SYMBOL(<fs_fcat>).
      <fs_fcat>-no_out = 'X'.
      CASE <fs_fcat>-fieldname.
        WHEN
        'ICON' OR
        'VNR' OR
        'VVS' OR
        'VART' OR
        'VNAME' OR
        'AEDAT' OR
        'AENAME' OR
        'TYPE' OR
        'MESSAGE'.
          CLEAR: <fs_fcat>-tech, <fs_fcat>-no_out.
        WHEN
        'ARCID' OR
        'ARCSID' OR
        'ARCFID' OR
        'ARCTYPE' OR
        'ARCHIVED_DATE' OR
        'ARCHIVED_TIME' OR
        'ARCHIVED_USER'.

          IF iv_arc_action <> mc->arc_action-mark_for_deletion.
            CLEAR: <fs_fcat>-no_out.
          ENDIF.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.


  METHOD set_icon.

    CASE cs_arc_return-type.
      WHEN mc->msgtype_a.
        cs_arc_return-icon = icon_message_critical_small.
      WHEN mc->msgtype_e.
        cs_arc_return-icon = icon_led_red.
      WHEN mc->msgtype_i.
        cs_arc_return-icon = icon_led_green.
      WHEN mc->msgtype_s.
        cs_arc_return-icon = icon_led_green.
      WHEN   mc->msgtype_w.
        cs_arc_return-icon = icon_led_yellow.
    ENDCASE.
  ENDMETHOD.


  METHOD set_return.
    DATA ls_return TYPE bapiret2.
    IF iv_type IS SUPPLIED.
      ls_return-type = iv_type.
    ELSE.
      ls_return-type = mc->msgtype_s.
    ENDIF.

    IF iv_id IS SUPPLIED.
      ls_return-id = iv_id.
    ELSE.
      ls_return-id = mc->msgid_sctqp.
    ENDIF.
    ls_return-number     = iv_number.
    ls_return-message_v1 = iv_message_v1.
    ls_return-message_v2 = iv_message_v2.
    ls_return-message_v3 = iv_message_v3.
    ls_return-message_v4 = iv_message_v4.


*       Klartext ermitteln
    MESSAGE ID ls_return-id TYPE ls_return-type NUMBER  ls_return-number
      WITH ls_return-message_v1 ls_return-message_v2 ls_return-message_v3 ls_return-message_v4
      INTO ls_return-message.



    APPEND INITIAL LINE TO ct_arc_return ASSIGNING FIELD-SYMBOL(<fs_arcret>).
    MOVE-CORRESPONDING ls_return TO <fs_arcret>.
    IF is_select IS NOT INITIAL.
      MOVE-CORRESPONDING is_select TO <fs_arcret>.
    ENDIF.
    IF is_arcnode IS NOT INITIAL.
      MOVE-CORRESPONDING is_arcnode TO <fs_arcret>.
    ENDIF.
    set_icon( CHANGING cs_arc_return = <fs_arcret> ).


  ENDMETHOD.
ENDCLASS.
