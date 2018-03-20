import numpy as np
cimport numpy as np
from numpy cimport ndarray
from numpy import nan

from cpython cimport list
from cpython.unicode cimport PyUnicode_InternFromString
import cython

from collections import defaultdict

def get_dtypes_first_line(char * chars, int nc, ndarray[np.uint8_t, cast=True] usecols_arr):
    cdef:
        Py_ssize_t i=0, j=0, n, start=0, k=0
        int x = 0, dec=0, denom = 1, sign = 1
        ndarray[np.int64_t] dtypes = np.zeros(nc, dtype='int64')
        ndarray[np.int64_t] dtype_loc = np.zeros(nc, dtype='int64')
        ndarray[np.int64_t] dtype_summary = np.zeros(5, dtype='int64')
        ndarray[object] vals = np.empty(nc, dtype='O')

        bint is_int = True
        bint is_float = False
        bint is_str = False
        bint begun = False

    dtypes = np.zeros(nc, dtype='int64')
    n = len(chars)

    # 0: unknown, 1 boolean, 2 int, 3 float, 4 str

    for i in range(n):
        if not usecols_arr[k]:
            if chars[i] == b',' or chars[i] == b'\n':
                k += 1
                start = i + 1
            continue

        if not begun:
            # remove white spaces in beginning
            if chars[i] == b' ':
                continue
            elif chars[i] == 45:
                sign = -1
                begun = True
                continue
            else:
                begun = True
        if chars[i] == b',' or chars[i] == b'\n':
            k += 1
            if i != start:
                temp = chars[start:i]
                if is_str:
                    if temp == b'True':
                        vals[j] = True
                        dtypes[j] = 1
                    elif temp == b'False':
                        vals[j] = False
                        dtypes[j] = 1
                    else:
                        # vals[j] = temp.decode('utf-8')
                        vals[j] = PyUnicode_InternFromString(temp)
                        dtypes[j] = 4
                elif is_float:
                    vals[j] = sign * (x + <double> dec / denom)
                    dtypes[j] = 3
                else:
                    vals[j] = sign * x
                    dtypes[j] = 2

            # reset - new value
            start = i + 1
            j += 1
            is_int = True
            is_str = False
            is_float = False
            x = 0
            dec = 0
            denom = 1
            begun = False
            sign = 1
        elif is_str:
            pass
        elif chars[i] >= 48 and chars[i] <= 57:
            if is_float:
                dec = dec * 10 + chars[i] - 48
                denom = denom * 10
            else:
                x = x * 10 + chars[i] - 48
        elif chars[i] == 46 and not is_float: #only first time sees decimal
            is_float = True
        else:
            is_str = True

    for i in range(nc):
        dtype_loc[i] = dtype_summary[dtypes[i]]
        dtype_summary[dtypes[i]] += 1

    return dtypes, dtype_loc, dtype_summary, vals

cdef double get_float(char * string):
    cdef:
        int x = 0
        int dec = 0
        int denom = 1
        int sign = 1
        int i = 0
        bint has_dec = False
        int n = len(string)
        int start = 0

    while string[start] == b' ':
        start += 1

    if string[start] == 45:
        sign = -1
        start += 1

    for i in range(start, n):
        if string[i] >= 48 and string[i] <= 57:
            if has_dec:
                dec = dec * 10 + string[i] - 48
                denom = denom * 10
            else:
                x = x * 10 + string[i] - 48
        elif string[i] == 46:
            has_dec = True

    return sign * (x + <double> dec / denom)

def read_csv(fn, long nr, int sep, int header, int skiprows_int, set skiprows_set, list usecols):
    cdef:
        bytes buf, first_buf
        list columns
        char * chars # const?
        char * first_line
        Py_ssize_t i=0, j=0,k=0, nc, start=0, end=0, n, act_row = 0, use_col_idx=0, count_py = 0

        ndarray[np.uint8_t, ndim=2, cast=True] a_bool
        ndarray[np.int64_t, ndim=2] a_int
        ndarray[np.float64_t, ndim=2] a_float
        ndarray[object, ndim=2] a_str

        bint is_int = True
        bint is_float = False
        bint is_str = False
        bint begun = False
        bint has_int = False
        bint has_num = False
        bint has_skiprows_set = bool(skiprows_set)
        bint has_usecols = bool(usecols)

        int x = 0, dec=0, denom = 1, sign = 1, jump = 0, ct_dec, nc_orig=0
        ndarray[np.int64_t] dtypes
        ndarray[np.int64_t] dtype_loc
        ndarray[np.int64_t] dtype_summary
        ndarray[object] vals
        ndarray[np.uint8_t, cast=True] usecols_arr

    py_sep = bytes(chr(sep), 'utf-8')

    if header == -1:
        nr = nr - len(skiprows_set) - skiprows_int
        with open(fn, "rb") as f:
            for i in range(skiprows_int):
                f.readline()
            while act_row in skiprows_set:
                skiprows_set.remove(act_row)
                f.readline()
                act_row += 1
            first_buf = f.readline()
            act_row += 1
            while act_row in skiprows_set:
                skiprows_set.remove(act_row)
                f.readline()
                act_row += 1
            nc = len(first_buf.split(py_sep))
            columns = ['a' + str(i) for i in range(nc)]
            buf = f.read()
    else:
        nr = nr - len(skiprows_set) - skiprows_int - header - 1
        with open(fn, "rb") as f:
            for i in range(skiprows_int + header):
                f.readline()
                act_row += 1

            columns = []
            col_set = set()
            for i, v in enumerate(f.readline().replace(b"\n", b"").split(py_sep)):
                # v = v.decode('utf8')
                v = PyUnicode_InternFromString(v)
                if v == '':
                    col_name = col_name = 'a' + str(i)
                else:
                    col_name = col_base = v

                k = 0
                while col_name in col_set:
                    col_name = col_base + '_' + str(k)
                    k += 1
                columns.append(col_name)
                col_set.add(col_name)
            act_row += 1

            while act_row in skiprows_set:
                skiprows_set.remove(act_row)
                f.readline()
                act_row += 1
            first_buf = f.readline()
            act_row += 1
            while act_row in skiprows_set:
                skiprows_set.remove(act_row)
                f.readline()
                act_row += 1

            buf = f.read() # this is fast, can keep in Python

    first_line = first_buf
    nc = len(columns)
    nc_orig = nc

    if has_usecols:
        if isinstance(usecols[0], (int, np.integer)):
            try:
                # test whether selection works - can ue negative indices
                usecols_new = np.arange(nc)[usecols]
            except IndexError:
                raise IndexError('The integer values in `usecols` cannot must be used to '
                                 f'select columns in a {nc}-item sequence')
        else:
            # assume we have column names
            usecols_new = []
            for col in usecols:
                usecols_new.append(columns.index(col))

        usecols_arr = np.zeros(nc, dtype='bool')
        usecols_arr[usecols_new] = True
        nc = usecols_arr.sum()
        columns = np.array(columns)[usecols_arr].tolist()
    else:
        usecols_arr = np.ones(nc, dtype='bool')

    dtypes, dtype_loc, dtype_summary, vals = get_dtypes_first_line(first_line, nc, usecols_arr)

    a_bool = np.empty((nr, dtype_summary[1]), dtype='bool', order='F')
    a_int = np.empty((nr, dtype_summary[2]), dtype='int64', order='F')
    a_float = np.empty((nr, dtype_summary[3]), dtype='float64', order='F')
    a_str = np.full((nr, dtype_summary[4]), '', dtype='O', order='F')

    for i in range(nc):
        if dtypes[i] == 1:
            a_bool[0, dtype_loc[i]] = vals[i]
        elif dtypes[i] == 2:
            a_int[0, dtype_loc[i]] = vals[i]
        elif dtypes[i] == 3:
            a_float[0, dtype_loc[i]] = vals[i]
        elif dtypes[i] == 4:
            a_str[0, dtype_loc[i]] = vals[i]

    i = 0
    k = 1

    chars = buf
    n = len(chars)

    dtypes_changed = defaultdict(list)

    while True:
        if i >= n:
            break

        if has_usecols:
            if not usecols_arr[use_col_idx]:
                while chars[i] != sep and chars[i] != b'\n':
                    i += 1
                # go to next row
                if chars[i] == b'\n':
                    j = 0
                    use_col_idx = 0
                    k += 1
                    act_row += 1
                else:
                    use_col_idx += 1

                i += 1
                continue

        if dtypes[j] == 4:
            start = i
            temp_list = []
            while chars[i] == b' ':
                i += 1

            while chars[i] != sep and chars[i] != b'\n':
                temp_list.append(chr(chars[i]))
                i += 1

            # only assign when a non-empty string is present - otherwise its already None
            if i != start:
                # a_str[k, dtype_loc[j]] = chars[start:i].decode('utf-8')
                a_str[k, dtype_loc[j]] = PyUnicode_InternFromString(chars[start:i])

        elif dtypes[j] == 2:
            ct_dec = 0
            x = 0
            sign = 1
            is_str = False
            has_int = False

            while chars[i] == b' ':
                i += 1

            start = i

            if chars[i] == 45:
                sign = -1
                i += 1

            while True:
                if chars[i] >= 48 and chars[i] <= 57:
                    x = x * 10 + chars[i] - 48
                    i += 1
                    has_int = True
                elif chars[i] == 46:
                    ct_dec += 1
                    i += 1
                elif chars[i] != sep and chars[i] != b'\n':
                    is_str = True
                    i += 1
                else:
                    break

            if has_int and ct_dec == 0 and not is_str:
                a_int[k, dtype_loc[j]] = sign * x
            elif is_str or ct_dec > 1:
                dtypes_changed[2].append(j)
                a_str = np.column_stack((a_str, np.empty(nr, dtype = 'O')))
                a_str[:k, dtype_summary[4]] = a_int[:k, dtype_loc[j]].astype('str')
                dtype_loc[j] = dtype_summary[4]
                dtypes[j] = 4
                dtype_summary[4] += 1
                if start != i:
                    # a_str[k, dtype_loc[j]] = chars[start:i].decode('utf-8')
                    a_str[k, dtype_loc[j]] = PyUnicode_InternFromString(chars[start:i])
            else: # ct_dec == 1 or start == i or not has_int:
                dtypes_changed[2].append(j)
                a_float = np.column_stack((a_float, a_int[:, dtype_loc[j]]))
                dtype_loc[j] = dtype_summary[3]
                dtype_summary[3] += 1
                dtypes[j] = 3
                if start == i:
                    a_float[k, dtype_loc[j]] = nan
                else:
                    a_float[k, dtype_loc[j]] = get_float(chars[start:i])

        elif dtypes[j] == 3:
            x = 0
            dec = 0
            denom = 1
            ct_dec = 0
            sign = 1
            has_num = False
            is_str = False

            while chars[i] == b' ':
                i += 1

            start = i

            if chars[i] == 45:
                sign = -1
                i += 1

            while True:
                if chars[i] >= 48 and chars[i] <= 57:
                    if ct_dec > 0:
                        dec = dec * 10 + chars[i] - 48
                        denom = denom * 10
                    else:
                        x = x * 10 + chars[i] - 48
                    i += 1
                    has_num = True
                elif chars[i] == 46:
                    ct_dec += 1
                    i += 1
                elif chars[i] != sep and chars[i] != b'\n':
                    is_str = True
                    i += 1
                else:
                    break

            if has_num and ct_dec <= 1 and not is_str:
                a_float[k, dtype_loc[j]] = sign * (x + <double> dec / denom)
            elif start == i:
                a_float[k, dtype_loc[j]] = nan
            else: # is_str or ct_dec > 1:
                dtypes_changed[3].append(j)
                a_str = np.column_stack((a_str, np.empty(nr, dtype = 'O')))
                a_str[:k, dtype_summary[4]] = a_float[:k, dtype_loc[j]].astype('str')
                dtype_loc[j] = dtype_summary[4]
                dtype_summary[4] += 1
                dtypes[j] = 4
                a_str[k, dtype_loc[j]] = PyUnicode_InternFromString(chars[start:i])

        elif dtypes[j] == 1:
            while chars[i] == b' ':
                i += 1

            start = i

            while chars[i] != sep and chars[i] != b'\n':
                i += 1

            if chars[start:i] == b'True':
                a_bool[k, dtype_loc[j]] = True
            elif chars[start:i] == b'False':
                a_bool[k, dtype_loc[j]] = True
            else:
                # change dtype to str
                dtypes_changed[1].append(j)
                a_str = np.column_stack((a_str, np.empty(nr, dtype = 'O')))
                a_str[:k, dtype_summary[4]] = a_bool[:k, dtype_loc[j]].astype('str')
                dtype_loc[j] = dtype_summary[4]
                dtype_summary[4] += 1
                dtypes[j] = 4
                if start == i:
                    # a_str[k, dtype_loc[j]] = chars[start:i].decode('utf-8')
                    a_str[k, dtype_loc[j]] = PyUnicode_InternFromString(chars[start:i])

        # unknown data types - must either be str or float but default to str
        # can change to float if
        elif dtypes[j] == 0:
            x = 0
            dec = 0
            denom = 1
            ct_dec = 0
            sign = 1
            has_num = False
            is_str = False

            while chars[i] == b' ':
                i += 1

            start = i

            if chars[i] == 45:
                sign = -1
                i += 1

            while True:
                if chars[i] >= 48 and chars[i] <= 57:
                    if ct_dec > 0:
                        dec = dec * 10 + chars[i] - 48
                        denom = denom * 10
                    else:
                        x = x * 10 + chars[i] - 48
                    i += 1
                    has_num = True
                elif chars[i] == 46:
                    ct_dec += 1
                    i += 1
                elif chars[i] != sep and chars[i] != b'\n':
                    is_str = True
                    i += 1
                else:
                    break

            if has_num and ct_dec <= 1 and not is_str:
                dtypes_changed[0].append(j)
                a_float = np.column_stack((a_float, np.full(nr, nan, dtype='float64')))
                dtype_loc[j] = dtype_summary[3]
                dtype_summary[3] += 1
                dtypes[j] = 3
                a_float[k, dtype_loc[j]] = x
            elif start != i:
                # its really a string now
                dtypes_changed[0].append(j)
                a_str = np.column_stack((a_str, np.empty(nr, dtype='O')))
                dtype_loc[j] = dtype_summary[4]
                dtype_summary[4] += 1
                dtypes[j] = 4
                a_str[k, dtype_loc[j]] = PyUnicode_InternFromString(chars[start:i])
                count_py += 1
                # a_str[k, dtype_loc[j]] = chars[start:i].decode('utf-8')

        i += 1
        j += 1
        use_col_idx += 1
        if use_col_idx == nc_orig:
            j = 0
            use_col_idx = 0
            k += 1
            act_row += 1

            if has_skiprows_set:
                while act_row in skiprows_set:
                    skiprows_set.remove(act_row)
                    while chars[i] != b'\n':
                        i += 1
                    i += 1
                    act_row += 1

                if len(skiprows_set) == 0:
                    has_skiprows_set = False

    is_unk = dtypes == 0
    unk_total = is_unk.sum()
    if unk_total > 0:
        # make unknown data types str
        a_unk = np.empty((nr, unk_total), dtype='O')
        a_str = np.column_stack((a_str, a_unk))
        dtypes[is_unk] = 4
        dtype_loc[is_unk] = np.arange(unk_total) + dtype_summary[4]

    return a_bool, a_int, a_float, a_str, columns, dtypes, dtype_loc