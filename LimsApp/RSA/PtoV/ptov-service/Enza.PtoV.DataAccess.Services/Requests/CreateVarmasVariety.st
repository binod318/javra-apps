<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:v01="http://contract.enzazaden.com/RandD/Eazy/Breezys/V01">
  <soapenv:Header/>
  <soapenv:Body>
    <v01:CreateVarmasVariety>
      <UserName>$Model.UserName$</UserName>
      <SynCode>$Model.SyncCode$</SynCode>
      <VaramsVarietyNr>$Model.VarmasVarietyNr$</VaramsVarietyNr>
      <GID>$Model.GID$</GID>
      <LotNumber>$Model.LotNr$</LotNumber>
      <Crop>$Model.CropCode$</Crop>
      <BreedingStation>$Model.BrStationCode$</BreedingStation>
      <IsParent>$Model.IsParent$</IsParent>      
      <TransferType>$Model.TransferType$</TransferType>
      <UsePONumber>$Model.UsePONumber$</UsePONumber>
      <ProgramfieldsData>
        <!--Zero or more repetitions:-->
        $Model.ProgramValues:{key|
          <ProgramFieldData>
            <PFTableName></PFTableName>
            <ProgramFieldCode>$key$</ProgramFieldCode>
            <ProgramFieldValue>$Model.ProgramValues.(key)$</ProgramFieldValue>
          </ProgramFieldData>
        }$
      </ProgramfieldsData>
      <ScreeningfieldsData>
        <!--Zero or more repetitions:-->
        $Model.ScrValues:{key|
          <ScreeningFieldData>
            <SFTableName></SFTableName>
            <ScreeningFieldNr>$key$</ScreeningFieldNr>
            <ScreeningFieldValue>$Model.ScrValues.(key)$</ScreeningFieldValue>
          </ScreeningFieldData>
        }$
      </ScreeningfieldsData>
    </v01:CreateVarmasVariety>
  </soapenv:Body>
</soapenv:Envelope>