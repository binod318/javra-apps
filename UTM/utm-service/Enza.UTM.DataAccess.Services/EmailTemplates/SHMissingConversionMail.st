<div>
  Dear Sir/Madam, <br/>
  
  Relation mapping for the following determinations are missing for seed health:<br/>
  
  Crop Code: $Model.CropCode$, Test Name: $Model.TestName$ <br/>
  <table border="1" cellpadding="0" cellspacing="0" width="400">
    <tr bgcolor='#C1BFBF'>
      <th>Determination</th>
      <th>Mapping Column</th>
	  <th>SampleType</th>
    </tr>
    $Model.Determinations:{item|
    <tr>
      <td>$item.DeterminationName$</td>
      <td>$item.MappingColumn$</td>
	  <td>$item.SampleType$</td>
    </tr>
    }$
  </table>
</div>