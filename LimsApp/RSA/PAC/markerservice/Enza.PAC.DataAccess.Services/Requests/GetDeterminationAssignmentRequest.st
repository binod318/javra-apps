<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://www.agrosolutions.nl/QualityConnect/20170301" xmlns:ns1="http://schemas.agrosolutions.nl/QualityConnect/20170301">
  <soapenv:Header/>
  <soapenv:Body>
    <ns:GetDeterminationAssignment>
      <ns:daParameters>
        <ns1:PageNumber>$Model.PageNumber$</ns1:PageNumber>
        <ns1:PageSize>$Model.PageSize$</ns1:PageSize>
        <ns1:Planner>$Model.Planner$</ns1:Planner>
        <ns1:StatusCode>$Model.StatusCode$</ns1:StatusCode>
      </ns:daParameters>
    </ns:GetDeterminationAssignment>
  </soapenv:Body>
</soapenv:Envelope>