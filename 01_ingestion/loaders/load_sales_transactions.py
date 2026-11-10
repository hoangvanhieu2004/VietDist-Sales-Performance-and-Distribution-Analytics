import sys; sys.path.append('..')
from load_base import run_loader

if __name__ == '__main__':
    run_loader('SRC01_sales_transactions.csv', 'sales_transactions')
