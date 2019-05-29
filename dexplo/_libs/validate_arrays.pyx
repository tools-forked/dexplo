#cython: boundscheck=False
#cython: wraparound=False
import numpy as np
cimport numpy as np
cimport cython
from numpy import nan
from numpy cimport ndarray
from libc.math cimport isnan
import warnings
import datetime


# def validate_1D_object_array(ndarray[object] arr, columns):
#     cdef int i
#     cdef int n = len(arr)
#
#     cur_dtype = type(arr[0])
#     for i in range(n):
#         if not isinstance(arr[i], cur_dtype):
#             raise TypeError(f'Found mixed data in column {columns[i]}')


def get_kind(obj):
    if isinstance(obj, (bool, np.bool_)):
        return 'bool'
    if isinstance(obj, (int, np.integer)):
        return 'int'
    if isinstance(obj, (float, np.floating)):
        if isnan(obj):
            return 'missing'
        return 'float'
    # np.str_ is subclass of str? same for bytes
    if isinstance(obj, (str, np.str_)):
        return 'str'
    if isinstance(obj, (datetime.date, datetime.datetime, np.datetime64)):
        return 'datetime'
    if isinstance(obj, (datetime.timedelta, np.timedelta64)):
        return 'timedelta'
    if obj is None:
        return 'missing'
    return 'unknown'


def maybe_convert_object_array(ndarray[object] arr, column):
    cdef int i = 0
    cdef int n = len(arr)

    for i in range(n):
        dtype = get_kind(arr[i])
        if dtype != 'missing':
            break

    if dtype == 'bool':
        return convert_bool_array(arr, column)
    if dtype == 'int':
        return convert_int_array(arr, column)
    if dtype == 'float':
        return arr.astype('float64')
    if dtype == 'str':
        return convert_str_array(arr, column)
    if dtype == 'datetime':
        return arr.astype('datetime64[ns]')
    if dtype == 'timedelta':
        return arr.astype('timedelta64[ns]')
    if dtype == 'unknown':
        raise ValueError(f'Value in column {column} row {i} is {arr[i]} with type {type(arr[i])}. '
                         'All values must be either bool, int, float, str or missing')
    else:
        warnings.warn('Column `{column}` contained all missing values. Converted to float')
        return arr.astype('float64')


def convert_bool_array(ndarray[object] arr, column):
    cdef int i
    cdef int n = len(arr)
    cdef ndarray[np.uint8_t, cast=True] result = np.empty(n, dtype='bool')

    for i in range(n):
        if not isinstance(arr[i], (bool, np.bool_)):
            raise ValueError(f'The first value of column `{column}` was a boolean. All the other '
                             'values in the array must also be a boolean. '
                             f'Found value {arr[i]} of type {type(arr[i])} in the {i}th row.')
        result[i] = arr[i]
    return result

def convert_int_array(ndarray[object] arr, column):
    cdef int i
    cdef int n = len(arr)
    cdef ndarray[np.int64_t] result = np.empty(n, dtype='int64')

    for i in range(n):
        if isinstance(arr[i], (float, np.floating)) or arr[i] is None:
            return arr.astype('float64')
        elif not isinstance(arr[i], (int, np.integer)):
            raise ValueError('The first value of column `{column}` was an integer. All the other '
                             'values in the array must either be integers or floats. '
                             f'Found value {arr[i]} of type {type(arr[i])} in the {i}th row.')
        result[i] = arr[i]
    return result


def convert_str_array(ndarray[object] arr, column):
    cdef int i
    cdef int n = len(arr)
    cdef ndarray[object] result = np.empty(n, dtype='O')
    nt = type(None)

    for i in range(n):
        if isinstance(arr[i], (float, np.floating)) and isnan(arr[i]):
            result[i] = None
        elif not isinstance(arr[i], (str, np.str_, nt)):
            raise ValueError(f'The first value of column `{column}` was a string. All the other '
                             'values in the array must either be strings or missing values. '
                             f'Found value {arr[i]} of type {type(arr[i])} in the {i}th row.')
        result[i] = arr[i]
    return result


def convert_obj_to_cat(ndarray[object] arr):
    cdef Py_ssize_t i, n = len(arr)
    cdef ndarray[np.uint32_t] arr_map = np.empty(len(arr), 'uint32', 'F')
    cdef dict d = {}

    for i in range(n):
        if isinstance(arr[i], (float, np.floating)) and isnan(arr[i]):
            arr_map[i] = d.setdefault(None, len(d))
        elif arr[i] is None:
            arr_map[i] = d.setdefault(None, len(d))
        else:
            arr_map[i] = d.setdefault(str(arr[i]), len(d))

    return arr_map, d

def convert_str_to_cat(ndarray arr):
    cdef Py_ssize_t i, n = len(arr)
    cdef ndarray[np.uint32_t] arr_map = np.empty(len(arr), 'uint32', 'F')
    cdef dict d = {}

    for i in range(n):
        arr_map[i] = d.setdefault(arr[i], len(d))

    return arr_map, d


def convert_str_to_cat_2d(ndarray arr):
    cdef Py_ssize_t i, j, n = len(arr), m = arr.shape[1]
    cdef ndarray[np.uint32_t, ndim=2] arr_map = np.empty((n, m), 'uint32', 'F')
    cdef dict d, str_map = {}

    for j in range(m):
        d = {}
        str_map = d
        for i in range(n):
            arr_map[i, j] = d.setdefault(arr[i, j], len(d))

    return arr_map, str_map


def convert_str_to_cat_list_2d(list arrs):
    cdef Py_ssize_t i, j, n = len(arrs[0]), m = len(arrs)
    cdef ndarray arr
    cdef ndarray[np.uint32_t, ndim=2] arr_map = np.empty((n, m), 'uint32', 'F')
    cdef dict d, str_map = {}, str_reverse_map = {}

    for j in range(m):
        d = {}
        str_map[j] = d
        arr = arrs[j]
        for i in range(n):
            arr_map[i, j] = d.setdefault(arr[i], len(d))
    for k, v in str_map.items():
        str_reverse_map[k] = list(v.keys())
    return arr_map, str_reverse_map


# def convert_datetime_array(ndarray[object] arr, column):
#     cdef int i
#     cdef int n = len(arr)
#     cdef ndarray[np.int64_t] result = np.empty(n, dtype='int64')
#
#     for i in range(n):
#         if not isinstance(arr[i], (datetime.date, datetime.datetime, np.datetime64)):
#             raise ValueError('The first value of column `{column}` was a datetime. All the other '
#                              'values in the array must be datetimes. '
#                              f'Found value {arr[i]} of type {type(arr[i])} in the {i}th row.')
#         result[i] = int(arr[i])
#     return result.astype('datetime64[ns]')
#
# def convert_timedelta_array(ndarray[object] arr, column):
#     cdef int i
#     cdef int n = len(arr)
#     cdef ndarray[np.int64_t] result = np.empty(n, dtype='int64')
#
#     for i in range(n):
#         if not isinstance(arr[i], (datetime.timedelta, np.timedelta64)):
#             raise ValueError('The first value of column `{column}` was a datetime. All the other '
#                              'values in the array must be datetimes. '
#                              f'Found value {arr[i]} of type {type(arr[i])} in the {i}th row.')
#         result[i] = arr[i]
#     return result.astype('timedelta64[ns]')

def is_equal_1d_object(ndarray[object] a, ndarray[object] b):
    cdef int i
    cdef int n = len(a)
    for i in range(n):
        if a[i] == b[i]:
            continue
        if a[i] is None and b[i] is None:
            continue
        if (isinstance(a[i], (float, np.floating)) and isnan(a[i]) and
            isinstance(b[i], (float, np.floating)) and isnan(b[i])):
            continue
        return False
    return True


def is_equal_str_cat_array(ndarray[np.uint32_t] a, ndarray[np.uint32_t] b, list srm_a, list srm_b):
    cdef Py_ssize_t i, n = len(a)

    for i in range(n):
        if srm_a[a[i]] != srm_b[b[i]]:
            return False
    return True


def validate_strings_in_object_array(ndarray[object] arr, columns=None):
    """
    Make sure only unicode strings are in array of type object
    """
    cdef int i
    cdef int n = len(arr)

    for i in range(n):
        if not isinstance(arr[i], str):
            if isinstance(arr[i], bytes):
                arr[i] = arr[i].decode()
            elif isinstance(arr[i], (float, np.floating)) and isnan(arr[i]):
                arr[i] = None
            elif arr[i] is None:
                pass
            elif columns:
                raise TypeError('Array of type "object" must only contain '
                                f'strings in column {columns[i]}')
            else:
                raise TypeError('Array of type "object" must only contain '
                                'strings')
    return arr


def isnan_object(ndarray[object, ndim=2] a):
    cdef int i, j
    cdef int nr = a.shape[0]
    cdef int nc = a.shape[1]
    cdef ndarray[np.uint8_t, cast=True] hasnan = np.zeros(nc, dtype='bool')
    for i in range(nr):
        for j in range(nc):
            if a[i][j] is None:
                hasnan[j] = True
                break
    return hasnan

def any_int(ndarray[np.int64_t] a):
    cdef int i
    cdef int n = len(a)
    for i in range(n):
        if a[i] != 0:
            return True
    return False

def any_float(ndarray[np.float64_t] a):
    cdef int i
    cdef int n = len(a)
    for i in range(n):
        if a[i] != 0 and not isnan(a[i]):
            return True
    return False

def any_bool(ndarray[np.int8_t, cast=True] a):
    cdef int i
    cdef int n = len(a)
    for i in range(n):
        if a[i] != 0:
            return True
    return False

def any_str(ndarray[object] a):
    cdef int i
    cdef int n = len(a)
    for i in range(n):
        if a[i] != '' and not a[i] is not nan:
            return True
    return False

def convert_nan_to_none(ndarray[object, ndim=2] a, int start, int num):
    cdef int i, j
    cdef int nr = a.shape[0]
    for i in range(nr):
        for j in range(start, start + num):
            if isnan(a[i, j]):
                a[i, j] = None

def fill_str_none(ndarray[object] a, np.uint8_t high):
    cdef int i, n = len(a)
    cdef ndarray[object] b = np.empty(n, dtype='O')
    cdef str fill

    if high:
        fill = chr(10 ** 6)
    else:
        fill = ''

    for i in range(n):
        if a[i] is None:
            b[i] = fill
        else:
            b[i] = a[i]
    return b

def make_object_datetime_array(ndarray[object, ndim=2] a, ndarray[np.uint64_t] b, int j, str unit):
    cdef int i
    cdef int nr = a.shape[0]
    cdef int nc = a.shape[1]

    for i in range(nr):
        a[i, j] = np.datetime64(b[i], unit)

def make_object_timedelta_array(ndarray[object, ndim=2] a, ndarray[np.uint64_t] b, int j, str unit):
    cdef int i
    cdef int nr = a.shape[0]
    cdef int nc = a.shape[1]

    for i in range(nr):
        a[i, j] = np.timedelta64(b[i], unit)

def make_object_str_array(list cur_list_map, ndarray[object, ndim=2] a,
                          ndarray[np.uint32_t] data, int j):
    cdef int i
    cdef int nr = a.shape[0]
    cdef int nc = a.shape[1]

    for i in range(nr):
        a[i, j] = cur_list_map[data[i]]

def bool_selection_str_mapping(ndarray[np.uint32_t, ndim=2] a, dict str_reverse_map):
    cdef Py_ssize_t i, j
    cdef int nr = a.shape[0], nc = a.shape[1], cur_code, new_val
    cdef list cur_srm, new_srm
    cdef ndarray[np.uint32_t] new_code
    cdef ndarray[np.uint32_t, ndim=2] b = np.empty((nr, nc), 'uint32', 'F')
    cdef dict new_str_reverse_map = {}

    for i in range(nc):
        cur_srm = str_reverse_map[i]
        new_code = np.full(len(cur_srm), 0, 'uint32')
        new_srm = [False]
        new_str_reverse_map[i] = new_srm
        for j in range(nr):
            cur_code = a[j, i]
            new_val = new_code[cur_code]
            if new_val == 0:
                new_val = len(new_srm)
                new_code[cur_code] = new_val
                new_srm.append(cur_srm[cur_code])
            b[j, i] = new_val
    return new_str_reverse_map, b
