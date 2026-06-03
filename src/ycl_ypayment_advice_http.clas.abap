CLASS ycl_ypayment_advice_http DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_http_service_extension .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS YCL_YPAYMENT_ADVICE_HTTP IMPLEMENTATION.


  METHOD if_http_service_extension~handle_request.
    DATA(req) = request->get_form_fields(  ).
    response->set_header_field( i_name = 'Access-Control-Allow-Origin' i_value = '*' ).
    response->set_header_field( i_name = 'Access-Control-Allow-Credentials' i_value = 'true' ).

    DATA(fiscalyear) = VALUE #( req[ name = 'fiscalyear' ]-value OPTIONAL ) .
    DATA(clearfiscalyear) = VALUE #( req[ name = 'clearfiscalyear' ]-value OPTIONAL ) .
    DATA(document) = VALUE #( req[ name = 'documentnumber' ]-value OPTIONAL ) .
    DATA(comcode) = VALUE #( req[ name = 'companycode' ]-value OPTIONAL ) .
    DATA(remark) = VALUE #( req[ name = 'remark' ]-value OPTIONAL ) .




*    todate = |{ todate+0(4) }{ todate+6(2) }{ todate+4(2) }|   .
*    fromdate = |{ fromdate+0(4) }{ fromdate+6(2) }{ fromdate+4(2) }|   .

    DATA(pdf2) = ypayment_advice=>read_posts( clearfiscalyear = clearfiscalyear  fiscalyear = fiscalyear  document = document comcode = comcode  remark = remark ) .
    response->set_text( pdf2  ).

  ENDMETHOD.
ENDCLASS.
