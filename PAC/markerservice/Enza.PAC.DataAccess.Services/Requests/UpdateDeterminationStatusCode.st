<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://www.agrosolutions.nl/ABSConnect/2017/01/01">
  <soapenv:Header/>
  <soapenv:Body>
    <ns:Quality_Connect>
      <ns:ListQualityConnect>
        $Model.DeterminationAssignments:{determinationassignment|
        <ns:Quality_Connect_obj>
          <ns:Determination_assignment>$determinationassignment.DetAssignmentID$</ns:Determination_assignment>
          <ns:Determination_status_code>$determinationassignment.ProductStatus$</ns:Determination_status_code>
          <ns:Utmost_ready_date>$determinationassignment.ExpectedReadyDate$</ns:Utmost_ready_date>
        </ns:Quality_Connect_obj>
        }$
      </ns:ListQualityConnect>
      <ns:Username>$Model.UserName;format="xml"$</ns:Username>
    </ns:Quality_Connect>
  </soapenv:Body>
</soapenv:Envelope>