import sys; sys.path.append('..')
from load_base import run_loader

FILE_NAME = 'SRC07_employee_master.xlsx'

if __name__ == '__main__':
    run_loader(FILE_NAME, 'employees', sheet_name='Employee_v1_StartYear')
    run_loader(FILE_NAME, 'employees', sheet_name='Employee_v2_Adjustment')
