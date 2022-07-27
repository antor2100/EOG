from xlsxwriter.workbook import Workbook


# Create an new Excel file and add a worksheet.
workbook = Workbook('SNPP_2022_mooncycles.xlsx')
worksheet = workbook.add_worksheet()

# Widen the first column to make the text clearer.
worksheet.set_column('A:A', 30)

# Insert an image.
worksheet.write('A2', 'Insert an image in a cell:')
worksheet.insert_image('B2', 'images/std.jpg')

workbook.close()
