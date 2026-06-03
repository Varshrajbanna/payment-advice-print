CLASS ypayment_advice DEFINITION
 PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
*    CLASS-DATA : template TYPE string .

    CLASS-METHODS :

      read_posts
        IMPORTING VALUE(fiscalyear)      TYPE string
                  VALUE(clearfiscalyear) TYPE string
*                  VALUE(vendor)   TYPE string
                  VALUE(document)        TYPE string
                  VALUE(comcode)         TYPE string
                  VALUE(remark)          TYPE string
*                  VALUE(clearingdocument)   TYPE string

        RETURNING VALUE(result12)        TYPE string
        RAISING   cx_static_check .
  PROTECTED SECTION.
  PRIVATE SECTION.

    CONSTANTS  lc_template_name TYPE string VALUE 'PaymentAdvice'.


ENDCLASS.



CLASS YPAYMENT_ADVICE IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    TRY.

    ENDTRY.

  ENDMETHOD.


  METHOD read_posts .

    DATA add1 TYPE string.
    DATA add2 TYPE string.
    DATA add3 TYPE string.
    DATA add4 TYPE string.
    DATA add5 TYPE string.
    DATA gstin TYPE string.
    DATA cin TYPE string.
    DATA pan TYPE string.

    IF comcode = '1000' .
      add1 = 'KRN Heat Exchanger And Refrigeration Limited' .
      add2 = 'EPIP, RIICO Industrial Area, 301705' .
      add3 = 'Rajasthan, Code-301705' .
      pan =  'PAN :AAGCK7380J' .
      cin =  'CIN: U29309RJ2017PLC058905' .
      gstin = 'GSTIN: 08AAGCK7380J1Z2' .

    ELSEIF comcode = '2000' .
      add1 = 'KRN HVAC PRODUCTS PRIVATE LIMITED' .
      add2 = 'Plot No. SP1-24, KRN HVAC Products Private Limited,' .
      add3 = 'Neemrana, Kolila Joga, Alwar, Rajasthan' .
      pan =  'PAN : AAKCK1357R' .
      cin =  'CIN : U29309RJ2017PLC058905' .
      gstin = 'GSTIN : 08AAKCK1357R1ZT' .

    ENDIF.



    SELECT  * FROM ypayment_advice_data  WITH PRIVILEGED ACCESS AS a
     WHERE a~clearingjournalentryfiscalyear = @clearfiscalyear
       AND a~companycode = @comcode
       AND a~accountingdocumenttype <> 'KZ'
*       AND a~accountingdocumenttype <> 'KG'   //COMMENTED BY VIDOD 11.07.2025(KRISHNPAL)
       AND a~accountingdocumenttype <> 'VC'
*       AND a~accountingdocumenttype <> 'ZA'
       AND a~clearingjournalentry = @document
       AND a~fiscalyear = @fiscalyear
       INTO TABLE @DATA(it_data) .


    SELECT  * FROM ypayment_advice_data WITH PRIVILEGED ACCESS AS a
    WHERE  a~accountingdocumenttype = 'KZ'
       AND a~companycode = @comcode
       and   a~clearingjournalentryfiscalyear = @clearfiscalyear
       AND a~accountingdocument = @document
       AND a~fiscalyear = @fiscalyear
       AND a~invoicereference <> ''
        APPENDING CORRESPONDING FIELDS OF TABLE @it_data.

*    DATA: where TYPE string.

******************************************supplier*****************************

    SELECT SINGLE * FROM i_operationalacctgdocitem AS a
    LEFT JOIN i_supplier AS c ON ( c~supplier = a~supplier )
    LEFT JOIN I_Address_2 WITH PRIVILEGED ACCESS AS d ON ( d~AddressID = c~AddressID )
    LEFT OUTER JOIN i_regiontext WITH PRIVILEGED ACCESS AS b ON ( b~region = c~region AND b~country = c~country )

    WHERE a~accountingdocument = @document
      AND a~fiscalyear    = @clearfiscalyear
      AND a~companycode   = @comcode
      AND a~financialaccounttype = 'K'
      INTO  @DATA(head_data).


***************************************supplier******************************
*    DATA xsml TYPE string.
    DATA bill_amt TYPE p DECIMALS 2.
    DATA pay_amt TYPE p DECIMALS 2.


    DATA amt TYPE p DECIMALS 2.
    DATA amount1 TYPE p DECIMALS 2.
    DATA amt_with_tds TYPE p DECIMALS 2.
    DATA amt_with_tds1 TYPE p DECIMALS 2.
    DATA settelbal TYPE p DECIMALS 2.
    DATA AMNTT TYPE P DECIMALS 2.


    SELECT SINGLE *   FROM i_operationalacctgdocitem AS a
    INNER JOIN i_journalentry AS b ON ( b~accountingdocument = a~accountingdocument
                                    AND b~companycode = a~companycode
                                    AND b~fiscalyear = a~fiscalyear
                                    AND b~isreversed <> 'X' AND b~isreversal <> 'X' )
     WHERE a~housebank IS NOT INITIAL
     AND a~accountingdocument = @document
*     AND a~fiscalyear = @clearfiscalyear
     AND a~fiscalyear = @fiscalyear
     AND a~companycode = @comcode
     INTO @DATA(hou_tot).

    SELECT SINGLE b~bankname FROM i_housebank WITH PRIVILEGED ACCESS AS a
      LEFT OUTER JOIN i_bank_2 WITH PRIVILEGED ACCESS AS b ON ( b~bankinternalid = a~bankinternalid )
      WHERE  a~housebank = @hou_tot-a-housebank INTO @DATA(bankname).

    SELECT SINGLE *  FROM i_suplrbankdetailsbyintid WITH PRIVILEGED ACCESS AS a
    LEFT OUTER JOIN i_bank_2 WITH PRIVILEGED ACCESS AS b ON ( b~bankinternalid = a~bank )
    WHERE  supplier = @head_data-a-supplier INTO @DATA(ifsccode).


    DATA(total1) =  abs( hou_tot-a-amountincompanycodecurrency )  .

    DATA(lv_xml) = |<Form>| &&
              |<bdyMain>| &&
              |<add1>{ add1 }</add1>| &&
              |<add2>{ add2 }</add2>| &&
              |<add3>{ add3 }</add3>| &&
              |<add4>{ add4 }</add4>| &&
              |<cin>{ cin }</cin>| &&
              |<gst>{ gstin }</gst>| &&
              |<pan>{ pan }</pan>| &&
              |<supplier>{ head_data-a-supplier }</supplier>| &&
              |<suppliername>{ head_data-c-suppliername }</suppliername>| &&
              |<address>{ head_data-d-streetprefixname1 } { head_data-d-StreetPrefixName2 } { head_data-d-StreetSuffixName1 } { head_data-d-StreetSuffixName2 } </address>| &&
              |<gstno>{ head_data-c-taxnumber3 }</gstno>| &&
              |<Subform4>| &&
              |<DocNo>{ document }</DocNo>| &&
              |</Subform4>| &&
              |<tblLineItems>|.

    LOOP AT it_data INTO DATA(wa_tab2).

***************************************PO NUMBER K LIYE ******************************
*      SELECT SINGLE  * FROM i_operationalacctgdocitem AS a
*       INNER JOIN i_journalentry AS b ON ( b~accountingdocument = a~accountingdocument AND b~companycode = a~companycode
*                                        AND b~fiscalyear = a~fiscalyear AND  b~isreversed <> 'X' AND b~isreversal <> 'X' )  WHERE
*      a~companycode = @wa_tab2-companycode AND ( ( a~originalreferencedocument = @wa_tab2-originalreferencedocument  AND @wa_tab2-accountingdocumenttype <> 'KZ' ) OR (
*      a~accountingdocument =  @wa_tab2-invoicereference AND @wa_tab2-accountingdocumenttype = 'KZ' ) )
*      AND a~fiscalyear = @wa_tab2-fiscalyear AND ( a~accountingdocumentitemtype = 'W' OR  a~accountingdocumentitemtype = 'M' )
*      INTO  @DATA(tab) .
***************************************PO NUMBER K LIYE ******************************

***************************************Document Date ******************************
      SELECT SINGLE  * FROM i_operationalacctgdocitem AS a
      INNER JOIN i_journalentry AS b ON ( b~accountingdocument = a~accountingdocument AND b~companycode = a~companycode
                                             AND b~fiscalyear = a~fiscalyear AND  b~isreversed <> 'X' AND b~isreversal <> 'X' )  WHERE
      a~companycode = @wa_tab2-companycode AND ( ( a~originalreferencedocument = @wa_tab2-originalreferencedocument AND @wa_tab2-accountingdocumenttype <> 'KZ' ) OR (
      a~accountingdocument =  @wa_tab2-invoicereference AND @wa_tab2-accountingdocumenttype = 'KZ' ) )
      AND a~fiscalyear = @wa_tab2-fiscalyear AND a~financialaccounttype = 'K'
      INTO  @DATA(jounral) .
***************************************Document  Date ******************************
******************************************************TDS ****************************
      SELECT SINGLE  SUM( amountincompanycodecurrency )  AS tds
      FROM i_operationalacctgdocitem WITH PRIVILEGED ACCESS AS a
      INNER JOIN i_journalentry AS b ON ( b~accountingdocument = a~accountingdocument
                                      AND b~companycode = a~companycode
                                      AND b~fiscalyear = a~fiscalyear
                                      AND b~isreversed <> 'X' AND b~isreversal <> 'X' )

      WHERE a~companycode = @wa_tab2-companycode
        AND a~fiscalyear = @wa_tab2-fiscalyear
        AND a~transactiontypedetermination = 'WIT'
        AND ( ( a~originalreferencedocument = @wa_tab2-originalreferencedocument AND @wa_tab2-accountingdocumenttype <> 'KZ' )
            OR ( a~accountingdocument =  @wa_tab2-invoicereference AND @wa_tab2-accountingdocumenttype = 'KZ' ) )
      GROUP BY a~accountingdocument,
               a~transactiontypedetermination
               INTO @DATA(tds1).

      IF tds1 IS INITIAL .
        SELECT SINGLE  SUM( a~amountincompanycodecurrency )  AS tds
       FROM i_operationalacctgdocitem WITH PRIVILEGED ACCESS AS a
       INNER JOIN i_journalentry AS b ON ( b~accountingdocument = a~accountingdocument
                                       AND b~companycode = a~companycode
                                       AND b~fiscalyear = a~fiscalyear
                                       AND b~isreversed <> 'X' AND b~isreversal <> 'X' )
       INNER JOIN i_operationalacctgdocitem AS c ON ( c~accountingdocument = a~accountingdocument
                                                  AND c~companycode = a~companycode
                                                  AND c~fiscalyear = a~fiscalyear
                                                  AND ( c~glaccount = '0001451004' OR c~glaccount = '0001451005'
                                                     OR c~glaccount = '0001451006' OR c~glaccount = '0001451007'
                                                     OR c~glaccount = '0001451008' OR c~glaccount = '0001451009'
                                                     OR c~glaccount = '0001451010' OR c~glaccount = '0001451011'
                                                     OR c~glaccount = '0001451020' ) )
       WHERE a~companycode = @wa_tab2-companycode AND
             a~invoicereference =  @wa_tab2-invoicereference
         AND a~accountingdocumenttype = 'KZ'
         AND a~fiscalyear = @wa_tab2-fiscalyear
       GROUP BY a~accountingdocument,
                a~transactiontypedetermination
                INTO @tds1.
      ENDIF.

      DATA tds TYPE p DECIMALS 2.
      tds = tds1.

      IF  wa_tab2-clearingjournalentry IS NOT INITIAL  AND wa_tab2-accountingdocumenttype <> 'KZ'.

*****************************************************TO CLEAR PARTIAL PAYMENT ***************************
        IF wa_tab2-clearingitem = '1' .

          SELECT SINGLE  SUM( amountincompanycodecurrency ) AS  amt
           FROM i_operationalacctgdocitem WITH PRIVILEGED ACCESS AS a
           INNER JOIN i_journalentry AS b ON ( b~accountingdocument = a~accountingdocument AND b~companycode = a~companycode
                                     AND b~fiscalyear = a~fiscalyear AND  b~isreversed <> 'X' AND b~isreversal <> 'X' )
           WHERE a~companycode = @wa_tab2-companycode AND
                 a~invoicereference =  @wa_tab2-accountingdocument AND a~accountingdocumenttype = 'KZ'
           AND   a~fiscalyear = @wa_tab2-clearingjournalentryfiscalyear AND a~clearingjournalentry  =   @wa_tab2-clearingjournalentry
           AND  a~clearingjournalentryfiscalyear = @wa_tab2-clearingjournalentryfiscalyear
           AND a~clearingitem = @wa_tab2-clearingitem
            INTO @DATA(amtparital).
          wa_tab2-amountincompanycodecurrency = wa_tab2-amountincompanycodecurrency + amtparital.




*          IF wa_tab2-amountincompanycodecurrency < 0 .
*            wa_tab2-amountincompanycodecurrency = wa_tab2-amountincompanycodecurrency * -1 .
*          ENDIF.
*
*          IF wa_tab2-amountincompanycodecurrency > 0 .
*            wa_tab2-amountincompanycodecurrency = wa_tab2-amountincompanycodecurrency * -1 .
*          ENDIF.

        ELSEIF wa_tab2-clearingitem <> '2' AND wa_tab2-clearingitem <> '4'.

          SELECT SINGLE  SUM( amountincompanycodecurrency ) AS  amt
           FROM i_operationalacctgdocitem WITH PRIVILEGED ACCESS AS a
           INNER JOIN i_journalentry AS b ON ( b~accountingdocument = a~accountingdocument AND b~companycode = a~companycode
                                     AND b~fiscalyear = a~fiscalyear AND  b~isreversed <> 'X' AND b~isreversal <> 'X' )
           WHERE a~companycode = @wa_tab2-companycode AND
                 a~accountingdocument =  @wa_tab2-clearingjournalentry AND a~accountingdocumenttype = 'KZ'
           AND   a~fiscalyear = @wa_tab2-clearingjournalentryfiscalyear AND a~clearingjournalentry  =   @wa_tab2-clearingjournalentry
           AND  a~clearingjournalentryfiscalyear = @wa_tab2-clearingjournalentryfiscalyear
           AND a~clearingitem = @wa_tab2-clearingitem
           GROUP BY a~accountingdocument INTO @wa_tab2-amountincompanycodecurrency.

        ENDIF.
*****************************************************TO CLEAR PARTIAL PAYMENT ***************************
      ENDIF.

*        jounral-a-amountincompanycodecurrency  =  abs( jounral-a-amountincompanycodecurrency ).
*        wa_tab2-amountincompanycodecurrency    = abs( wa_tab2-amountincompanycodecurrency ) .
*        tds    = abs( tds ) .   COMMENTED BY VIDOD...


      IF wa_tab2-accountingdocumenttype = 'KZ' .

        SELECT SINGLE documentreferenceid FROM ypayment_advice_data WITH PRIVILEGED ACCESS AS a
         WHERE a~accountingdocument = @wa_tab2-invoicereference
           AND a~fiscalyear = @wa_tab2-fiscalyear
           AND a~companycode = @wa_tab2-companycode
        INTO @wa_tab2-documentreferenceid .

      ENDIF.

      DATA amount2 TYPE p DECIMALS 2.
      DATA cdamount2 TYPE p DECIMALS 2.

      amount2 = jounral-a-amountincompanycodecurrency.

      DATA: lv_start_date TYPE sy-datum,
            lv_end_date   TYPE sy-datum,
            lv_diff       TYPE i.

      IF jounral-a-clearingdate IS INITIAL .

        SELECT SINGLE postingdate FROM i_operationalacctgdocitem WITH PRIVILEGED ACCESS AS a
          WHERE a~accountingdocumenttype = 'KZ'
          AND a~accountingdocument = @document
          AND fiscalyear = @fiscalyear
          AND a~companycode = @comcode
             INTO  @jounral-a-clearingdate.

      ENDIF.

      lv_start_date =  jounral-a-postingdate . " Start date
      lv_end_date = jounral-a-clearingdate.   " End date
      lv_diff = ( lv_end_date - lv_start_date ) + 1. " Difference in day

      SELECT SINGLE SUM( amountincompanycodecurrency ) FROM ypayment_advice_data WITH PRIVILEGED ACCESS AS a WHERE
      a~documentreferenceid = @wa_tab2-documentreferenceid AND a~fiscalyear = @wa_tab2-fiscalyear AND a~companycode = @wa_tab2-companycode
      AND a~debitcreditcode = 'S' AND a~accountingdocumenttype = 'KG' INTO @cdamount2 .

*wa_tab2-AmountInCompanyCodeCurrency = wa_tab2-AmountInCompanyCodeCurrency - CDamount2 .
      DATA pending_amt TYPE p DECIMALS 2.
      pending_amt =   amount2  - cdamount2 - wa_tab2-amountincompanycodecurrency.
      amount2 = amount2 + tds .



"""""""""""""""""""""""""""""""""""""""""""""""""""""


amntt = amntt + wa_tab2-AmountInCompanyCodeCurrency.

DATA ABSS TYPE P DECIMALS 2.

ABSS = abs( wa_tab2-amountincompanycodecurrency ) .






""""""""""""""""""""""""""""""""""""""""""""""""""""""""""



      lv_xml = lv_xml &&
                  |<rowLineItemNode>| &&
                  |<txtDocumentReference>{ wa_tab2-documentreferenceid   }</txtDocumentReference>| &&
                  |<dttDocumentDate>{ jounral-a-documentdate+6(2) }/{ jounral-a-documentdate+4(2) }/{ jounral-a-documentdate+0(4) }</dttDocumentDate>| &&
                  |<BillAmount>{ amount2 * -1 }</BillAmount>| &&
*                  |<BillAmount>{ abss }</BillAmount>| &&
                  |<TDSAmount>{ tds }</TDSAmount>| &&
*                  |<cdamount>{ cdamount2 }</cdamount>| &&
                  |<cdamount>{ '0.00' }</cdamount>| &&
                  |<paymentAmt>{ wa_tab2-amountincompanycodecurrency * -1  }</paymentAmt>| &&
*                  |<paymentAmt>{ abss }</paymentAmt>| &&
                  |<paymentdate>{ jounral-a-clearingdate+6(2) }/{ jounral-a-clearingdate+4(2) }/{ jounral-a-clearingdate+0(4) }</paymentdate>| &&
*                  |<PendingAmt>{ pending_amt }</PendingAmt>| &&
                  |<PendingAmt>{ '0.00' }</PendingAmt>| &&
                  |<days>{ lv_diff }</days>| &&
                  |</rowLineItemNode>| .


      DATA amounttot TYPE p DECIMALS 2.
      amounttot = amounttot + jounral-a-amountincompanycodecurrency.

      CLEAR : jounral,tds,wa_tab2,amtparital,amount2,cdamount2,tds1.

    ENDLOOP.

 amntt = abs( amntt )  .
 amounttot = abs( amounttot ).

    lv_xml = lv_xml &&
                    |<TOTAL>{ amntt }</TOTAL>| &&
                    |<TOT></TOT>| &&
                    |<rowLineItemNode1>| &&
                    |<Totam></Totam>| &&
                    |</rowLineItemNode1>| &&
                    |</tblLineItems>| &&
                    |<BankName>{ ifsccode-a-bank }</BankName>| &&
                    |<AccountNo>{ ifsccode-a-bankaccount }</AccountNo>| &&
                    |<Amount>{ amounttot }</Amount>| &&
                    |<txtCustomMessage></txtCustomMessage>| &&
                    |</bdyMain>| &&
                    |</Form>|.


    REPLACE ALL OCCURRENCES OF '&' IN lv_xml WITH 'and'.

    CALL METHOD zadobe_print=>adobe(
      EXPORTING
        xml       = lv_xml
        form_name = 'PaymentAdvice'
      RECEIVING
        result    = result12 ).


  ENDMETHOD.
ENDCLASS.
