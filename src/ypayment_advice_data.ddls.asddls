@AbapCatalog.sqlViewName: 'YPAYMENTADVICE'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Cds For Payment Advice Data'
define view YPAYMENT_ADVICE_DATA as select from I_OperationalAcctgDocItem as a
inner join I_JournalEntry as b on ( b.AccountingDocument = a.AccountingDocument and b.FiscalYear = a.FiscalYear 
                               and b.CompanyCode = a.CompanyCode and  b.IsReversed <> 'X' and b.IsReversal <> 'X' ) 
{
    
   key a.AccountingDocument,
   key a.FiscalYear, 
   key a.CompanyCode,
   key a.ClearingJournalEntry,
   key a.ClearingJournalEntryFiscalYear,
       a.AccountingDocumentType,
       a.InvoiceReference,
       a.AmountInCompanyCodeCurrency,
       a.OriginalReferenceDocument,
       b.DocumentReferenceID,
       a.ClearingItem,
       a.DebitCreditCode
}

