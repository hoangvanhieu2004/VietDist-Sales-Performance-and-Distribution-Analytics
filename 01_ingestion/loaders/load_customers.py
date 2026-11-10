import sys; sys.path.append('..')
from load_base import run_loader

if __name__ == '__main__':
    run_loader('SRC03_customer_master.csv', 'customers')
