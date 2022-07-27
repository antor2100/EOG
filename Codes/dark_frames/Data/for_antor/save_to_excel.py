from openpyxl import load_workbook
import csv
import sys

wb = load_workbook(filename = 'test.xlsx')

try:
	del wb[sys.argv[1]]
except:
	print("sheet not in list")

ws = wb.active
ws = wb.create_sheet(title=sys.argv[1])

with open('granule_summary.csv') as file_obj:
    reader_obj = csv.reader(file_obj)
      
    for row in reader_obj:
        ws.append(row)

wb.save(filename = 'test.xlsx')
