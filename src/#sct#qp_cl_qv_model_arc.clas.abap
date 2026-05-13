CLASS /sct/qp_cl_qv_model_arc DEFINITION
  PUBLIC
  INHERITING FROM /sct/qp_cl_qv_model
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor                     RAISING /sct/qp_cx_error.

    METHODS /sct/qp_if_model~do_arc_restore REDEFINITION.
    METHODS get_base_root                   REDEFINITION.

  PROTECTED SECTION.
    DATA mo_data_arc TYPE REF TO /sct/qp_cl_data_arc.

    METHODS do_add_base_archiv_block IMPORTING is_node_target TYPE /sct/qp_s_qvc_data_sort
                                     EXPORTING es_base        TYPE /sct/qp_s_base
                                     CHANGING  ct_base        TYPE /sct/qp_tu_base
                                     RAISING   /sct/qp_cx_error.

    METHODS do_add_base            REDEFINITION.
    METHODS get_guid               REDEFINITION.

    METHODS do_add_base_vart_block REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS /sct/qp_cl_qv_model_arc IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).

    /sct/qp_cl_factory=>get_instance( EXPORTING iv_classcondition = mc->data_type-arc
                                      CHANGING  co_instance       = mo_data->mo_arc ).

    mo_data_arc ?= mo_data->mo_arc.
  ENDMETHOD.

  METHOD do_add_base.
    " --------------------------------------------------------------------*
    " FT20170419 Note 1257 Archivierung
    "   Ein kleines Teil (DO_ADD_BASE_VART_BLOCK) ist überdefiniert worden
    "   Für ROOT-Knoten Parent-Folder = ARCID
    " --------------------------------------------------------------------*
    " MD, 2019.05.09: N2132 Gesamtkopie entfernt und stattdessen
    "   DO_ADD_BASE_VART_BLOCK mit Parameter IS_NODE_TARGET ergänzt,
    "   womit die Redefinition dieser spezifischen Methode ausreicht
    " --------------------------------------------------------------------*
    " MD, 2019.05.09: N2143 Einlesen des
    "   Archiv-Customizings vor Laden der Hierarchie
    " --------------------------------------------------------------------*

    IF is_node_target IS NOT INITIAL.
      DATA(lo_cust) = CAST /sct/qp_cl_qv_cust_service_arc( mo_cust ).
      lo_cust->set_active( iv_arcsid = is_node_target-arcsid ).
    ENDIF.

    super->do_add_base( EXPORTING is_base_parent    = is_base_parent
                                  is_node_target    = is_node_target
                                  is_noderel_target = is_noderel_target
                        IMPORTING es_base_child     = es_base_child
                        CHANGING  ct_node_data      = ct_node_data
                                  ct_base           = ct_base ).
  ENDMETHOD.

  METHOD do_add_base_archiv_block.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " FT20170419 Note 1257 Archivierung : Angelegt

    " Ergeugt einen funktionslosen Gruppenknoten für VARTen
    " pro arcid
    " --------------------------------------------------------------------*
    " AD, 2025.09.09, NOTE-3614
    " MS_BASE am Knoten
    " --------------------------------------------------------------------*

    DATA lv_vblock TYPE /sct/qp_vblock.
    DATA ls_node   LIKE is_node_target.

    IF is_node_target-arcid IS INITIAL.
      lv_vblock = mc->arcid_current. " '#CURRENT#' = aktuelle Daten
    ELSE.
      lv_vblock = is_node_target-arcid. " Daten aus dem Archiv ARCID
    ENDIF.

    CLEAR es_base.

    READ TABLE mt_base INTO es_base WITH KEY vblock = lv_vblock.

    IF sy-subrc = 0.
      " Fertig und raus
      RETURN.
    ENDIF.

    CLEAR es_base.
    es_base-key       = mo_tools->do_create_guid( ).
    es_base-guid      = es_base-key.
    es_base-vblock    = lv_vblock.
*    es_base-vart      = lv_vblock.
    es_base-knotentyp = mc->knotentyp_g.
    es_base-workmode  = mc->workmode_display.

    " Ein paar Daten aufbauen
    CLEAR ls_node.
    ls_node-guid      = es_base-guid.
    ls_node-vart      = es_base-vart.
    ls_node-vblock    = es_base-vblock.
    ls_node-knotentyp = es_base-knotentyp.

    " Jetzt Instanz aufbauen
    es_base-instance = do_create_node_instance( ir_base      = REF #( es_base )
                                                is_node_data = ls_node ).

    APPEND es_base TO mt_base.
  ENDMETHOD.

  METHOD do_add_base_vart_block.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " MD, 2019.05.09: N2132 Angelegt
    "   Zur besseren Kapselung statt Gesamtkopie von DO_ADD_BASE
    "   Dazu musste nur ein optionaler Parameter IS_NODE_TARGET angelegt werden
    " --------------------------------------------------------------------*

    do_add_base_archiv_block( EXPORTING is_node_target = is_node_target
                              IMPORTING es_base        = es_base
                              CHANGING  ct_base        = ct_base ).
  ENDMETHOD.

  METHOD /sct/qp_if_model~do_arc_restore.
    " *********************************************************************
    " Änderungslog
    " *********************************************************************
    " FT20170420 Note 1257 Archvierung : angelegt
    " --------------------------------------------------------------------*

    " Überschreibt eine vorhandene Hierarchie
    " mit Archiv-Daten

    " Source = is_base ( mit arcid und Ext-GUID )
    " Die original DB-GUID muss gefunden werden (aus /sct/qp_cl_data_arc)
    " und die Daten mussen ersetzt werden

    mo_data_arc->restore( iv_arcid         = ir_base->instance->ms_node_data-arcid
                          iv_root_guid_map = ir_base->instance->ms_node_data-guid ).
  ENDMETHOD.

  METHOD get_base_root.
    DATA(ls_node) = is_node.

    IF  is_node-arcid IS NOT INITIAL
    AND is_node-guid  IS NOT INITIAL.

      " DB-GUID -> OUT-GUID
      ls_node-guid = mo_data_arc->get_mapped_guid( iv_arcid   = is_node-arcid
                                                   iv_guid_db = is_node-guid ).

      IF ls_node-guid IS INITIAL.
        CLEAR: es_base,
               es_base_root.
        RETURN.
      ENDIF.

    ELSE.
      " Sonst nichts tun, kein Mapping
    ENDIF.

    super->get_base_root( EXPORTING is_base            = is_base
                                    is_node            = ls_node
                                    iv_check_timestamp = iv_check_timestamp
                          IMPORTING es_base            = es_base
                                    es_base_root       = es_base_root ).
  ENDMETHOD.

  METHOD get_guid.
    IF iv_arcid IS NOT INITIAL.
      " Archivdaten : Mapping lesen
      rv_guid = mo_data_arc->get_mapped_guid( iv_arcid   = iv_arcid
                                              iv_guid_db = iv_guid ).
    ELSE.
      " Standarddaten
      rv_guid = iv_guid.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
