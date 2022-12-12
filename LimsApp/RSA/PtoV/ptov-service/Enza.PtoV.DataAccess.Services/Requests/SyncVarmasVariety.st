<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:v01="http://contract.enzazaden.com/RandD/Eazy/Breezys/V01">
  <soapenv:Header/>
  <soapenv:Body>
    <v01:UpdateVarmasScreeningData>
      <UserName>$Model.UserName$</UserName>
      <GermplasmList>
        <!--Zero or more repetitions:-->
        $Model.Germplasms:{o|
        <Germplasm>
          <SynCode>$o.SyncCode$</SynCode>
          <GID>$o.GID$</GID>
          <VarietyNr>$o.VarietyNr$</VarietyNr>
          <LotNumber>$o.LotNumber$</LotNumber>
          <ScreeningFieldsData>
            <!--Zero or more repetitions:-->
            $o.ScreeningFields:{x|
            <ScreeningFieldData>
              <ScreeningFieldNr>$x.ScreeningFieldNr$</ScreeningFieldNr>
              <ScreeningFieldValue>$x.ScreeningFieldValue$</ScreeningFieldValue>
            </ScreeningFieldData>
            }$
          </ScreeningFieldsData>
        </Germplasm>
        }$
      </GermplasmList>
    </v01:UpdateVarmasScreeningData>
  </soapenv:Body>
</soapenv:Envelope>