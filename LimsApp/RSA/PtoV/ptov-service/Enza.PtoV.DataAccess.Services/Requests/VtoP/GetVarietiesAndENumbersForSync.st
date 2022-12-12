<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:v01="http://contract.enzazaden.com/RandD/Eazy/Breezys/V01">
  <soapenv:Header/>
  <soapenv:Body>
    <v01:GetVarietyInfo>
      <UserName>$Model.UserName$</UserName>
      <SynCode>$Model.SyncCode$</SynCode>
      <Crop>$Model.Crop$</Crop>
      <VarietyNr>$Model.VarietyNr$</VarietyNr>
      <TimestampIn>$Model.Timestamp$</TimestampIn>
      <RequestedData>$Model.RequestedData$</RequestedData>      
    </v01:GetVarietyInfo>
  </soapenv:Body>
</soapenv:Envelope>