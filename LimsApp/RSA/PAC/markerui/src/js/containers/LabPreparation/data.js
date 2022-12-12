const columns = [
  {
    ColumnID: 'Action',
    Label: 'Action',
    Order: 0,
    IsVisible: true,
    Editable: false
  },
  {
    ColumnID: 'Folder',
    Label: 'Folder',
    Order: 0,
    IsVisible: true,
    Editable: false
  },
  {
    ColumnID: 'Crop',
    Label: 'Crop',
    Order: 0,
    IsVisible: true,
    Editable: false
  },
  {
    ColumnID: 'Method',
    Label: 'Method',
    Order: 0,
    IsVisible: true,
    Editable: false
  },
  {
    ColumnID: 'Platform',
    Label: 'Platform',
    Order: 0,
    IsVisible: true,
    Editable: false
  },
  {
    ColumnID: 'Plates',
    Label: '#Plates',
    Order: 0,
    IsVisible: true,
    Editable: false
  },
  {
    ColumnID: 'markers',
    Label: '#markers',
    Order: 0,
    IsVisible: true,
    Editable: false
  },
  {
    ColumnID: 'TraitMarkers',
    Label: 'Trait',
    Order: 0,
    IsVisible: true,
    Editable: true,
    checkbox: true
  },
  {
    ColumnID: 'Variety',
    Label: 'Variety',
    Order: 0,
    IsVisible: true,
    Editable: false
  },
  {
    ColumnID: 'samp',
    Label: 'Sample Number',
    Order: 0,
    IsVisible: true,
    Editable: false
  }
];
const dat = [
  {
    Folder: 'Folder 1',
    Crop: 'TO',
    Method: 'PAC-12',
    Platform: 'Sequencing',
    Plates: '16',
    markers: '0',
    TraitMarkers: '0',
    Variety: 'Santasio',
    samp: 2342555
  },
  {
    Folder: '',
    Crop: '',
    Method: '',
    Platform: '',
    Plates: '16',
    markers: '-',
    TraitMarkers: '-',
    Variety: 'Santasio',
    samp: 2342555
  },
  {
    Folder: 'Folder 2',
    Crop: 'TO',
    Method: 'PAC-46',
    Platform: 'Sequencing',
    Plates: '16',
    markers: '0',
    TraitMarkers: '0',
    Variety: 'Pic0',
    samp: 2342555
  }
];

export {
  columns
  , dat
};
