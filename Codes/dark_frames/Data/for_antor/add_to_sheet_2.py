from openpyxl import load_workbook
 
FilePath = "/Users/antor/Documents/EOG/Codes/dark_frames/Data/for_antor/test.xlsx"
ExcelWorkbook = load_workbook(FilePath)
writer = pd.ExcelWriter(FilePath, engine = 'openpyxl')
writer.book = ExcelWorkbook
arrary= [1, 2, 3]
df.to_excel(writer, sheet_name = 'new sheet 2')
writer.save()
writer.close()
