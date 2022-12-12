using System;
using System.Data;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using Enza.PtoV.BusinessAccess.Interfaces;
using Enza.PtoV.Common.Exceptions;
using Enza.PtoV.Common.Extensions;
using Enza.PtoV.DataAccess.Data.Interfaces;
using Enza.PtoV.Entities.Args;

namespace Enza.PtoV.BusinessAccess.Services
{
    public class VarietyService : IVarietyService
    {
        private readonly IVarietyRepository _repository;
        private readonly IPedigreeRepository _pedigreeRepo;
        private readonly IPhenomeServices _phenomeService;
        private readonly IMasterRepository _masterRepository;

        public VarietyService(IVarietyRepository repository, 
            IPedigreeRepository pedigreeRepo,
            IPhenomeServices phenomeService,
            IMasterRepository masterRepository)
        {
            _repository = repository;
            _pedigreeRepo = pedigreeRepo;
            _phenomeService = phenomeService;
            _masterRepository = masterRepository;
        }

        public Task<bool> ReplaceLOTAsync(int gID, int lotGID)
        {
            return _repository.ReplaceLOTAsync(gID, lotGID);
        }

        public async Task<bool> ReplaceLOTAsync(HttpRequestMessage request, ReplaceLotRequestArgs args)
        {
            //validate if PO nr of maintainer of selected female and maintainer of selected female contains same Po nr
            var varieties = await _repository.GetVarietiesAsync(new[] { args.GID });
            if (!varieties.Any())
                throw new BusinessException("Variety not found.");

            //Inactive variety 
            var inactiveList = new[] { "100","500","600","700","800","900","999","P2","P3","PD" };
            var inputVar = varieties.FirstOrDefault(o => o.GID == args.GID);
            if( inactiveList.FirstOrDefault(o => o.EqualsIgnoreCase(inputVar.VarmasStatus))!= null )
                throw new BusinessException("Variety with varmas status " + inputVar.VarmasStatus + " can not be used for Replace Lot.");

            var variety = varieties.FirstOrDefault();
            var transferType = await _masterRepository.GetTransferTypePerCropAsync(variety.CropCode);
            if (transferType == null)
            {
                throw new BusinessException("Crop not found on PtoV Master crop table.");
            }

            //validate if UsePOnr is enabled and both selected GID has their PO nr
            if (transferType.UsePONr)
            {
                if (string.IsNullOrWhiteSpace(variety.PONumber))
                {
                    throw new BusinessException("PO nr is not available for selected GID in PtoV.");
                }
                args.Data.TryGetValue("PO nr", out string poNr);
                if (string.IsNullOrWhiteSpace(poNr))
                {
                    throw new BusinessException("PO nr is not available for selected GID in pedigree.");
                }
                if (variety.Maintainer > 0 && string.IsNullOrWhiteSpace(variety.MaintainerPONr))
                {
                    throw new BusinessException($"PO nr of maintainer GID {variety.Maintainer} is not available.");
                }
                if (!variety.PONumber.EqualsIgnoreCase(poNr))
                {
                    throw new BusinessException($"PO nr of GID {variety.GID} and { args.LotGID} don't match with each other.");
                }
            }
            if (transferType.HasCms)
            {
                if (variety.Maintainer > 0)
                {
                    await _phenomeService.ValidatePONrForCMSCropAsync(request, variety, args.LotGID, transferType);
                }
            }

            //import lot if doesn't exist
            var data = await _repository.PhenomeLotIDExistsAsync(args.PhenomeLotID);
            if (!data.Any())
            {
                await ProcessAndImportData(request, args);
            }
            else
            {
                var lotData = data.GroupBy(x => new { x.LotID, x.GID }).Select(x => x.Key.GID).FirstOrDefault();
                if(lotData != args.LotGID)
                {
                    throw new BusinessException("Selected Inventory ID is already linked with different GID. Please contact data team for further process.");
                }
                //import if lot is present but variety is not
                else
                {
                    await ProcessAndImportData(request, args);
                }
            }
            return await _repository.ReplaceLOTAsync(args);
        }

        private async Task ProcessAndImportData(HttpRequestMessage request, ReplaceLotRequestArgs args)
        {
            var fixedCols = _phenomeService.PhenomeToPToVColumns();

            var dtCellTVP = new DataTable("TVP_Cell");
            var dtRowTVP = new DataTable("TVP_ImportVarieties");
            var dtColumnsTVP = new DataTable("TVP_Column");
            var lotTVP = new DataTable("TVP_Lot");
            //prepare all TVPs here
            _phenomeService.PrepareTVPs(dtRowTVP, dtColumnsTVP, dtCellTVP, lotTVP);
            var colInfo = await _repository.GetColumnDetailForGermplasm(args.GID);
            if (!colInfo.Any())
            {
                //wrong values passed on parameter
                throw new System.Exception("Invalid request paremeter");
            }
            var importedColumns = colInfo.ToList();

            var drRow = dtRowTVP.NewRow();
            int colCount = 0;

            var drLot = lotTVP.NewRow();
            drLot["ID"] = args.PhenomeLotID;
            drLot["GID"] = args.LotGID;
            drLot["Is Default"] = 1;
            lotTVP.Rows.Add(drLot);

            foreach (var _data in args.Data)
            {
                var drCol = dtColumnsTVP.NewRow();
                //prepare column values on tvp
                drCol["ColumnNr"] = colCount;
                drCol["ColumnLabel"] = _data.Key;
                drCol["DataType"] = "NVARCHAR(MAX)";
                dtColumnsTVP.Rows.Add(drCol);

                //prepare row values in tvp
                if (fixedCols.ContainsKey(_data.Key))
                {
                    if (_data.Key.EqualsIgnoreCase("Gen"))
                    {
                        if (string.IsNullOrWhiteSpace(_data.Value))
                            throw new BusinessException($"Generation code value is blank or empty for GID {args.GID}");
                    }
                    var fixedCol = fixedCols[_data.Key];
                    var cellval = _data.Value;
                    drRow[fixedCol.Name] = cellval.ToText();
                }
                else if (!string.IsNullOrWhiteSpace(_data.Value))
                {
                    var colnumber = importedColumns.IndexOf(importedColumns.FirstOrDefault(x => x.ColumnLabel.EqualsIgnoreCase(_data.Key)));
                    var drCell = dtCellTVP.NewRow();
                    drCell["RowNr"] = 0;
                    drCell["ColumnNr"] = colCount;
                    drCell["Value"] = _data.Value;
                    dtCellTVP.Rows.Add(drCell);
                }
                colCount++;
            }
            drRow["RowNr"] = 0;
            drRow["GID"] = args.LotGID;
            dtRowTVP.Rows.Add(drRow);

            await _repository.ImportGermplasmFromPedigree(dtRowTVP, dtColumnsTVP, dtCellTVP, lotTVP, args.GID);
        }

        public Task<DataTable> ReplaceLOTLookupAsync(int gID)
        {
            return _repository.ReplaceLOTLookupAsync(gID);
        }

        public Task UpdateProductSegmentsAsync(UpdateProductSegmentsRequestArgs requestArgs)
        {
            return _repository.UpdateProductSegmentsAsync(requestArgs);
        }

        public async Task<bool> UndoReplaceLOTAsync(UndoReplaceLotRequestArgs args)
        {
            return await _repository.UndoReplaceLOTAsync(args);
        }
    }
}
