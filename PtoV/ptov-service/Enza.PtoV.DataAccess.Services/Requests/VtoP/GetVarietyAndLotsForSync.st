<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:v01="http://contract.enzazaden.com/RandD/Eazy/Breezys/V01">
   <soapenv:Header/>
   <soapenv:Body>
      <v01:GetExternalLots>
         <UserName>$Model.UserName$</UserName>
         <SynCode>$Model.SyncCode$</SynCode>
         <Crop>$Model.CropCode$</Crop>
         <LotNumber>$Model.LotNr$</LotNumber>
         <RequestedData>$Model.RequestedData$</RequestedData>
      </v01:GetExternalLots>
   </soapenv:Body>
</soapenv:Envelope>