<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:v01="http://contract.enzazaden.com/RandD/Eazy/Breezys/V01">
  <soapenv:Header/>
  <soapenv:Body>
    <v01:UpdateExternalLots>
      <UserName>$Model.UserName$</UserName>
      <SynCode>$Model.SyncCode$</SynCode>
      <LotInfo>
        $Model.Lots: { lot|
        <Lot>
          <LotNr>$lot.LotNr$</LotNr>
          <PhenomeLotNr>$lot.PhenomeLotNr$</PhenomeLotNr>
          <VarietyNr>$lot.VarietyNr$</VarietyNr>
          <PhenomeGID>$lot.PhenomeGID$</PhenomeGID>
        </Lot>
        }$
      </LotInfo>
    </v01:UpdateExternalLots>
  </soapenv:Body>
</soapenv:Envelope>