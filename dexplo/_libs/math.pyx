#asdfcython: boundscheck=False
#asfdcython: wraparound=False
import numpy as np
cimport numpy as np
from numpy cimport ndarray
from numpy import nan
from cpython cimport set, list
from libc.math cimport isnan, floor, ceil
import groupby as gb
import math as _math
from libc.stdlib cimport free, malloc
from libc.string cimport memcpy

try:
    import bottleneck as bn
except ImportError:
    import numpy as bn

cdef:
    np.float64_t MAX_FLOAT = np.finfo(np.float64).max
    np.float64_t MIN_FLOAT = np.finfo(np.float64).min

    np.int64_t MAX_INT = np.iinfo(np.int64).max
    np.int64_t MIN_INT = np.iinfo(np.int64).min

def min_max_int(ndarray[np.int64_t] a):
    cdef:
        Py_ssize_t i
        int n = len(a)
        long low = a[0], high = a[0]

    for i in range(n):
        if a[i] < low:
            low = a[i]
        if a[i] > high:
            high = a[i]
    return low, high

def min_max_float(ndarray[np.float64_t] a):
    cdef:
        Py_ssize_t i
        n = len(a)
        np.float64_t low = a[0], high = a[0]

    for i in range(n):
        if a[i] < low:
            low = a[i]
        if a[i] > high:
            high = a[i]
    return low, high

def min_max_int2(ndarray[np.int64_t, ndim=2] a, axis):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        ndarray[np.int64_t] lows
        ndarray[np.int64_t] highs
        np.int64_t low, high

    if axis == 0:
        lows = np.empty(nc, dtype='int64')
        highs = np.empty(nc, dtype='int64')
        for i in range(nc):
            low = a[0, i]
            high = a[0, i]
            for j in range(nr):
                if a[j, i] < low:
                    low = a[j, i]
                if a[j, i] > high:
                    high = a[j, i]
            lows[i] = low
            highs[i] = high
    return lows, highs


def nunique_str(ndarray[np.uint32_t, ndim=2] a, dict str_reverse_map,
                axis, count_na, hasnans, **kwargs):
    cdef:
        Py_ssize_t i, j
        int nr, nc
        ndarray[np.int64_t] result
        np.uint32_t cur_num
        bint has_missing
        set s

    if axis == 0:
        nc = len(str_reverse_map)
        result = np.empty(nc, dtype='int64')
        for i in range(nc):
            result[i] = len(str_reverse_map[i])
            if hasnans[i] and not count_na:
                result[i] -= 1
    if axis == 1:
        nr = a.shape[0]
        nc = a.shape[1]
        result = np.empty(nr, 'int64', 'F')
        for i in range(nr):
            s = set()
            has_missing = False
            for j in range(nc):
                cur_num = a[i, j]
                if cur_num == 0:
                    has_missing = True
                else:
                    s.add(str_reverse_map[j][cur_num])
            result[j] = len(s)
            if count_na and has_missing:
                result[j] += 1
    return result

def nunique_int(ndarray[np.int64_t, ndim=2] a, axis, **kwargs):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        ndarray[np.int64_t] result
        set s = set()

    lows, highs = min_max_int2(a, axis)
    if (highs - lows < 10_000_000).all():
        return nunique_int_bounded(a, axis, lows, highs)

    if axis == 0:
        result = np.empty(nc, dtype='int64')
        for i in range(nc):
            s = set()
            for j in range(nr):
                s.add(a[j, i])
            result[i] = len(s)
    else:
        result = np.empty(nr, dtype='int64')
        for i in range(nr):
            s = set()
            for j in range(nc):
                s.add(a[i, j])
            result[i] = len(s)

    return result

def nunique_bool(ndarray[np.uint8_t, cast=True, ndim=2] a, axis, **kwargs):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        ndarray[np.uint8_t, cast=True] unique
        list result
        ndarray[np.int64_t] final_result

    if axis == 0:
        final_result = np.empty(nc, dtype='int64')
        for i in range(nc):
            result = []
            unique = np.zeros(2, dtype=bool)
            for j in range(nr):
                if not unique[a[j, i]]:
                    unique[a[j, i]] = True
                    result.append(a[j, i])
                if len(result) == 2:
                    break
            final_result[i] = len(result)
    else:
        final_result = np.empty(nr, dtype='int64')
        for i in range(nr):
            result = []
            unique = np.zeros(2, dtype=bool)
            for j in range(nc):
                if not unique[a[i, j]]:
                    unique[a[i, j]] = True
                    result.append(a[i, j])
                if len(result) == 2:
                    break
            final_result[i] = len(result)

    return final_result

def nunique_float(ndarray[np.float64_t, ndim=2] a, axis, count_na=False, **kwargs):
    cdef:
        Py_ssize_t i, j
        int ct_nan, nr = a.shape[0], nc = a.shape[1]
        ndarray[np.int64_t] result
        set s

    if axis == 0:
        result = np.empty(nc, dtype='int64')
        if count_na:
            for i in range(nc):
                s = set()
                ct_nan = 0
                for j in range(nr):
                    if isnan(a[j, i]):
                        ct_nan = 1
                    else:
                        s.add(a[j, i])
                result[i] = len(s) + ct_nan
        else:
            for i in range(nc):
                s = set()
                for j in range(nr):
                    if not isnan(a[j, i]):
                        s.add(a[j, i])
                result[i] = len(s)

    if axis == 1:
        result = np.empty(nr, dtype='int64')
        if count_na:
            for i in range(nr):
                s = set()
                ct_nan = 0
                for j in range(nc):
                    if isnan(a[j, i]):
                        ct_nan = 1
                    else:
                        s.add(a[i, j])
                result[i] = len(s) + ct_nan
        else:
            for i in range(nr):
                s = set()
                for j in range(nc):
                    if not isnan(a[i, j]):
                        s.add(a[i, j])
                result[i] = len(s)

    return result

def nunique_int_bounded(ndarray[np.int64_t, ndim=2] a, axis,
                        ndarray[np.int64_t] lows, ndarray[np.int64_t] highs,  **kwargs):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        ndarray[np.uint8_t, cast=True] unique
        np.int64_t count, amin, rng
        ndarray[np.int64_t] result

    if axis == 0:
        result = np.empty(nc, dtype='int64')
        for i in range(nc):
            count = 0
            amin = lows[i]
            rng = highs[i] - lows[i] + 1
            unique = np.zeros(rng, dtype=bool)
            for j in range(nr):
                if not unique[a[j, i] - amin]:
                    unique[a[j, i] - amin] = True
                    count += 1
            result[i] = count
    else:
        result = np.empty(nr, dtype='int64')
        for i in range(nr):
            count = 0
            amin = lows[i]
            rng = highs[i] - lows[i] + 1
            unique = np.zeros(rng, dtype=bool)
            for j in range(nc):
                if not unique[a[i, j] - amin]:
                    unique[a[i, j] - amin] = True
                    count += 1
            result[i] = count
    return result

def sum_int(ndarray[np.int64_t, ndim=2] a, axis, **kwargs):
    cdef:
        long *arr = <long*> a.data
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        ndarray[np.int64_t] total

    if axis == 0:
        total = np.zeros(nc, dtype=np.int64)
        for i in range(nc):
            for j in range(nr):
                total[i] += arr[i * nr + j]
    else:
        total = np.zeros(nr, dtype=np.int64)
        for i in range(nr):
            for j in range(nc):
                total[i] += arr[j * nr + i]
    return total

def sum_bool(ndarray[np.uint8_t, ndim=2, cast=True] a, axis, **kwargs):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        ndarray[np.int64_t] total

    if axis == 0:
        total = np.zeros(nc, dtype='int64')
        for i in range(nc):
            for j in range(nr):
                if a[j, i]:
                    total[i] += 1
    else:
        total = np.zeros(nr, dtype='int64')
        for i in range(nr):
            for j in range(nc):
                if a[i, j]:
                    total[i] += 1
    return total.astype(np.int64)

def sum_float(ndarray[np.float64_t, ndim=2] a, axis, hasnans, **kwargs):
    cdef:
        double *arr = <double*> a.data
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        long idx
        ndarray[np.float64_t] total

    if axis == 0:
        total = np.zeros(nc, dtype=np.float64)
        for i in range(nc):
            if hasnans[i] is None or hasnans[i]:
                for j in range(nr):
                    if not isnan(arr[i * nr + j]):
                        total[i] += arr[i * nr + j]
            else:
                for j in range(nr):
                    total[i] += arr[i * nr + j]

    else:
        total = np.zeros(nr, dtype=np.float64)
        for i in range(nc):
            if hasnans[i] is None or hasnans[i]:
                for j in range(nr):
                    if not isnan(arr[i * nr + j]):
                        total[j] += arr[i * nr + j]
            else:
                for j in range(nr):
                    total[j] += arr[i * nr + j]
    return total

def sum_str(ndarray[np.uint32_t, ndim=2] a, dict str_reverse_map, axis, hasnans):
    cdef:
        Py_ssize_t i, j
        np.uint32_t nr = a.shape[0], nc = a.shape[1], ct, cur_num
        ndarray[np.uint32_t] arr
        dict new_str_reverse_map = {}
        list cur_srm
        str cur_val
        bint has_one_string

    if axis == 0:
        arr = np.ones(nc, 'uint32', 'F')
        for i in range(nc):
            cur_srm = str_reverse_map[i]
            cur_total = ''
            if hasnans[i] is None or hasnans[i]:
                has_one_string = False
                for j in range(nr):
                    cur_num = a[j, i]
                    if cur_num != 0:
                        cur_val = cur_srm[cur_num]
                        cur_total += cur_val
                        has_one_string = True
                if has_one_string:
                    new_str_reverse_map[i] = [False, cur_total]
                else:
                    new_str_reverse_map[i] = [False]
            else:
                for j in range(nr):
                    cur_total += cur_srm[a[j, i]]
                new_str_reverse_map[i] = [cur_total]
    else:
        arr = np.ones(nr, 'uint32', 'F')
        cur_sm = {False: 0}
        cur_srm = [False]
        for i in range(nr):
            ct = 0
            cur_total = ''
            has_one_string = False
            for j in range(nc):
                cur_num = a[i, j]
                if cur_num != 0:
                    cur_val = str_reverse_map[cur_num]
                    cur_total += cur_val
                    has_one_string = True
            if has_one_string:
                if cur_total in cur_sm:
                    arr[i] = cur_sm[cur_total]
                else:
                    arr[i] = len(cur_sm)
                    cur_sm[cur_total] = len(cur_sm)
                    cur_srm.append(cur_total)
            else:
                arr[i] = 0
    return arr, new_str_reverse_map

def mode_int(ndarray[np.int64_t, ndim=2] a, axis, hasnans, keep):
    cdef:
        Py_ssize_t i, j
        int order, low, high, last, nr = a.shape[0], nc = a.shape[1]
        ndarray[np.int64_t] result, col_arr, uniques, counts, groups, max_groups

    if axis == 0:
        result = np.empty(nc, dtype='int64')
        for i in range(nc):
            col_arr = a[:, i]
            low, high = _math.min_max_int(col_arr)
            if high - low < 10_000_000:
                uniques, counts = gb.value_counts_int_bounded(col_arr, low, high)
                uniques = uniques[counts == counts.max()]
            else:
                groups, counts = gb.value_counts_int(col_arr)
                max_groups = groups[counts == counts.max()]
                uniques = col_arr[max_groups]
            if len(uniques) == 1:
                result[i] = uniques[0]
            else:
                if keep == 'low':
                    result[i] = uniques.min()
                else:
                    result[i] = uniques.max()
    else:
        result = np.empty(nr, dtype='int64')
        for i in range(nr):
            col_arr = a[i, :]
            low, high = _math.min_max_int(col_arr)
            if high - low < 10_000_000:
                uniques, counts = gb.value_counts_int_bounded(col_arr, low, high)
                uniques = uniques[counts == counts.max()]
            else:
                groups, counts = gb.value_counts_int(col_arr)
                max_groups = groups[counts == counts.max()]
                uniques = col_arr[max_groups]
            if len(uniques) == 1:
                result[i] = uniques[0]
            else:
                if keep == 'low':
                    result[i] = uniques.min()
                else:
                    result[i] = uniques.max()

    return result

def mode_float(ndarray[np.float64_t, ndim=2] a, axis, hasnans, keep):
    cdef:
        Py_ssize_t i, j
        int order, low, high, last, nr = a.shape[0], nc = a.shape[1]
        ndarray[np.int64_t] groups, counts, max_groups
        ndarray[np.float64_t] result, col_arr, uniques

    if axis == 0:
        result = np.empty(nc, dtype='float64')
        for i in range(nc):
            col_arr = a[:, i]
            groups, counts = gb.value_counts_float(col_arr, dropna=True)

            if len(counts) == 0:
                result[i] = nan
            else:
                max_groups = groups[counts == counts.max()]
                uniques = col_arr[max_groups]

                if keep == 'low':
                    result[i] = uniques.min()
                else:
                    result[i] = uniques.max()
    else:
        result = np.empty(nr, dtype='float64')
        for i in range(nr):
            col_arr = a[i, :]
            groups, counts = gb.value_counts_float(col_arr, dropna=True)

            if len(counts) == 0:
                result[i] = nan
            else:
                max_groups = groups[counts == counts.max()]
                uniques = col_arr[max_groups]

                if keep == 'low':
                    result[i] = uniques.min()
                else:
                    result[i] = uniques.max()
    return result

def mode_str(ndarray[object, ndim=2] a, axis, hasnans, keep):
    cdef:
        Py_ssize_t i, j
        int order, low, high, last, nr = a.shape[0], nc = a.shape[1]
        ndarray[np.int64_t] groups, counts, max_groups
        ndarray[object] result, col_arr, uniques

    if axis == 0:
        result = np.empty(nc, dtype='O')
        for i in range(nc):
            col_arr = a[:, i]
            groups, counts = gb.value_counts_str(col_arr, dropna=True)

            if len(counts) == 0:
                result[i] = None
            else:
                max_groups = groups[counts == counts.max()]
                uniques = col_arr[max_groups]
                if keep == 'low':
                    result[i] = uniques.min()
                else:
                    result[i] = uniques.max()
    else:
        result = np.empty(nr, dtype='O')
        for i in range(nr):
            col_arr = a[i, :]
            groups, counts = gb.value_counts_str(col_arr, dropna=True)
            if len(counts) == 0:
                result[i] = None
            else:
                max_groups = groups[counts == counts.max()]
                uniques = col_arr[max_groups]
                if keep == 'low':
                    result[i] = uniques.min()
                else:
                    result[i] = uniques.max()
    return result

def mode_bool(ndarray[np.uint8_t, ndim=2, cast=True] a, axis, hasnans, keep):
    cdef:
        Py_ssize_t i, j
        int order, low, high, last, nr = a.shape[0], nc = a.shape[1]
        ndarray[np.int64_t] groups, counts
        ndarray[np.int8_t, cast=True] result, col_arr, uniques

    if axis == 0:
        result = np.empty(nc, dtype='bool')
        for i in range(nc):
            col_arr = a[:, i]
            uniques, counts = gb.value_counts_bool(col_arr)
            uniques = uniques[counts == counts.max()]

            if len(uniques) == 1:
                result[i] = uniques[0]
            else:
                if keep == 'low':
                    result[i] = uniques.min()
                else:
                    result[i] = uniques.max()
    else:
        result = np.empty(nr, dtype='bool')
        for i in range(nr):
            col_arr = a[i, :]
            uniques, counts = gb.value_counts_bool(col_arr)
            uniques = uniques[counts == counts.max()]

            if len(uniques) == 1:
                result[i] = uniques[0]
            else:
                if keep == 'low':
                    result[i] = uniques.min()
                else:
                    result[i] = uniques.max()
    return result

def prod_int(ndarray[np.int64_t, ndim=2] a, axis, **kwargs):
    cdef:
        long *arr = <long*> a.data
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        ndarray[np.int64_t] total

    if axis == 0:
        total = np.ones(nc, dtype=np.int64)
        for i in range(nc):
            for j in range(nr):
                total[i] *= arr[i * nr + j]
    else:
        total = np.zeros(nr, dtype=np.int64)
        for i in range(nr):
            for j in range(nc):
                total[i] *= arr[j * nr + i]
    return total

def prod_bool(ndarray[np.uint8_t, ndim=2, cast=True] a, axis, **kwargs):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        ndarray[np.int64_t] total

    if axis == 0:
        total = np.ones(nc, dtype='int64')
        for i in range(nc):
            for j in range(nr):
                total[i] *= a[j, i]
    else:
        total = np.zeros(nr, dtype='int64')
        for i in range(nr):
            for j in range(nc):
                total[i] *= a[i, j]
    return total

def prod_float(ndarray[np.float64_t, ndim=2] a, axis, hasnans, **kwargs):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        ndarray[np.float64_t] total
        double *arr = <double*> a.data
        long idx

    if axis == 0:
        total = np.ones(nc, dtype=np.float64)
        for i in range(nc):
            for j in range(nr):
                if not isnan(arr[i * nr + j]):
                    total[i] *= arr[i * nr + j]
            # else:
            #     for j in range(nr):
            #         total[i] *= arr[i * nr + j]

    else:
        total = np.zeros(nr, dtype=np.float64)
        for i in range(nc):
            for j in range(nr):
                if not isnan(arr[i * nr + j]):
                    total[j] *= arr[i * nr + j]
            # else:
            #     for j in range(nr):
            #         total[j] *= arr[i * nr + j]
    return total

def max_int(ndarray[np.int64_t, ndim=2] a, axis, **kwargs):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        long *arr = <long*> a.data
        ndarray[np.int64_t] amax
    
    if axis ==0:
        amax = np.empty(nc, dtype='int64')
        for i in range(nc):
            amax[i] = a[0, i]
            for j in range(nr):
                if arr[i * nr + j] > amax[i]:
                    amax[i] = arr[i * nr + j]
    else:
        amax = a[:, 0].copy('F')
        for i in range(nc):
            for j in range(nr):
                if arr[i * nr + j] > amax[j]:
                    amax[j] = arr[i * nr + j]
    return amax

def min_int(ndarray[np.int64_t, ndim=2] a, axis, **kwargs):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        long *arr = <long*> a.data
        ndarray[np.int64_t] amin

    if axis == 0:
        amin = np.empty(nc, dtype='int64')
        for i in range(nc):
            amin[i] = a[0, i]
            for j in range(nr):
                if arr[i * nr + j] < amin[i]:
                    amin[i] = arr[i * nr + j]
    else:
        amin = a[:, 0].copy('F')
        for i in range(nc):
            for j in range(nr):
                if arr[i * nr + j] < amin[j]:
                    amin[j] = arr[i * nr + j]
    return amin


def max_bool(ndarray[np.uint8_t, ndim=2, cast=True] a, axis, **kwargs):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        unsigned char *arr = <unsigned char*> a.data
        ndarray[np.uint8_t] amax
        
    if axis == 0:
        amax = np.zeros(nc, dtype=np.uint8)
        for i in range(nc):
            for j in range(nr):
                if arr[i * nr + j] == 1:
                    amax[i] = 1
                    break
    else:
        amax = np.zeros(nr, dtype=np.uint8)
        for i in range(nc):
            for j in range(nr):
                if arr[i * nr + j] == 1:
                    amax[j] = 1
                    break
    return amax.astype(np.int64)

def min_bool(ndarray[np.uint8_t, ndim=2, cast=True] a, axis, **kwargs):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        unsigned char *arr = <unsigned char*> a.data
        ndarray[np.uint8_t] amin

    if axis == 0:
        amin = np.ones(nc, dtype=np.uint8)
        for i in range(nc):
            for j in range(nr):
                if arr[i * nr + j] == 0:
                    amin[i] = 0
                    break
    else:
        amin = np.ones(nr, dtype=np.uint8)
        for i in range(nc):
            for j in range(nr):
                if arr[i * nr + j] == 0:
                    amin[j] = 0
                    break
    return amin.astype(np.int64)

def max_float(ndarray[np.float64_t, ndim=2] a, axis, hasnans):
    cdef:
        Py_ssize_t i, j, k
        int nr = a.shape[0], nc = a.shape[1]
        double *arr = <double*> a.data
        ndarray[np.float64_t] amax

    if axis == 0:
        amax = np.full(nc, nan, dtype=np.float64)
        for i in range(nc):
            if hasnans[i] is None or hasnans[i]:
                k = 0
                while isnan(arr[i * nr + k]) and k < nr - 1:
                    k += 1
                amax[i] = arr[i * nr + k]
                for j in range(k, nr):
                    if not isnan(arr[i * nr + j]):
                        if arr[i * nr + j] > amax[i]:
                            amax[i] = arr[i * nr + j]
            else:
                amax[i] = arr[i * nr]
                for j in range(nr):
                    if arr[i * nr + j] > amax[i]:
                        amax[i] = arr[i * nr + j]
    else:
        amax = np.full(nr, nan, dtype=np.float64)
        if hasnans.sum() > 0:
            for i in range(nr):
                k = 0
                while isnan(arr[k * nr + i]) and k < nc - 1:
                    k += 1
                amax[i] = arr[k * nr + i]
                for j in range(k, nc):
                    if not isnan(arr[j * nr + i]):
                        if arr[j * nr + i] > amax[i]:
                            amax[i] = arr[j * nr + i]
        else:
            for i in range(nr):
                for j in range(nc):
                    if arr[j * nr + i] > amax[i]:
                        amax[i] = arr[j * nr + i]
    return amax

def min_float(ndarray[np.float64_t, ndim=2] a, axis, hasnans):
    cdef:
        Py_ssize_t i, j, k
        int nr = a.shape[0], nc = a.shape[1]
        double *arr = <double*> a.data
        ndarray[np.float64_t] amin

    if axis == 0:
        amin = np.full(nc, nan, dtype=np.float64)
        for i in range(nc):
            if hasnans[i] is None or hasnans[i]:
                k = 0
                while isnan(arr[i * nr + k]) and k < nr - 1:
                    k += 1
                amin[i] = arr[i * nr + k]
                for j in range(k, nr):
                    if not isnan(arr[i * nr + j]):
                        if arr[i * nr + j] < amin[i]:
                            amin[i] = arr[i * nr + j]
            else:
                amin[i] = arr[i * nr]
                for j in range(nr):
                    if arr[i * nr + j] < amin[i]:
                        amin[i] = arr[i * nr + j]
    else:
        amin = np.full(nr, nan, dtype=np.float64)
        if hasnans.sum() > 0:
            for i in range(nr):
                k = 0
                while isnan(arr[k * nr + i]) and k < nc - 1:
                    k += 1
                amin[i] = arr[k * nr + i]
                for j in range(k, nc):
                    if not isnan(arr[j * nr + i]):
                        if arr[j * nr + i] < amin[i]:
                            amin[i] = arr[j * nr + i]
        else:
            for i in range(nr):
                for j in range(nc):
                    if arr[j * nr + i] < amin[i]:
                        amin[i] = arr[j * nr + i]
    return amin

def max_str(ndarray[np.uint32_t, ndim=2] a, dict str_reverse_map, axis, hasnans, **kwargs):
    cdef:
        Py_ssize_t i, j, k
        int nr = a.shape[0], nc = a.shape[1], num_vals, cur_code
        list cur_srm
        str cur_max_min, cur_val
        dict new_str_reverse_map = {}, cur_sm = {}
        ndarray[np.uint32_t, ndim=2] codes
        bint has_one_string

    if axis == 0:
        codes = np.ones((1, nc), dtype='uint32', order='F')
        for i in range(nc):
            cur_srm = str_reverse_map[i]
            num_vals = len(cur_srm)
            if num_vals == 1:
                new_str_reverse_map[i] = [False]
                codes[0, i] = 0
                continue
            else:
                cur_max_min = cur_srm[1]
                for j in range(2, num_vals):
                    cur_val = cur_srm[j]
                    if cur_val > cur_max_min:
                        cur_max_min = cur_val
            new_str_reverse_map[i] = [False, cur_max_min]
    else:
        codes = np.zeros((nr, 1), dtype='uint32', order='F')
        cur_srm = [False]
        cur_sm = {False: 0}

        for i in range(nr):
            has_one_string = False
            for j in range(nc):
                cur_code = a[i, j]
                if cur_code != 0:
                    cur_max_min = str_reverse_map[j][cur_code]
                    has_one_string = True
                    break
            for k in range(j, nc):
                cur_code = a[i, k]
                if cur_code != 0:
                    cur_val = str_reverse_map[k][cur_code]
                    if cur_val > cur_max_min:
                        cur_max_min = cur_val
            if has_one_string:
                if cur_max_min in cur_sm:
                    codes[i, 1] = cur_sm[cur_max_min]
                else:
                    codes[i, 1] = len(cur_sm)
                    cur_sm[cur_max_min] = len(cur_sm)
                    cur_srm.append(cur_max_min)
        new_str_reverse_map[0] = cur_srm
    return codes, new_str_reverse_map

def min_str(ndarray[np.uint32_t, ndim=2] a, dict str_reverse_map, axis, hasnans, **kwargs):
    cdef:
        Py_ssize_t i, j, k
        int nr = a.shape[0], nc = a.shape[1], num_vals, cur_code
        list cur_srm
        str cur_max_min, cur_val
        dict new_str_reverse_map = {}, cur_sm = {}
        ndarray[np.uint32_t, ndim=2] codes
        bint has_one_string

    if axis == 0:
        codes = np.ones((1, nc), dtype='uint32', order='F')
        for i in range(nc):
            cur_srm = str_reverse_map[i]
            num_vals = len(cur_srm)
            if num_vals == 1:
                new_str_reverse_map[i] = [False]
                codes[0, i] = 0
                continue
            else:
                cur_max_min = cur_srm[1]
                for j in range(2, num_vals):
                    cur_val = cur_srm[j]
                    if cur_val < cur_max_min:
                        cur_max_min = cur_val
            new_str_reverse_map[i] = [False, cur_max_min]
    else:
        codes = np.zeros((nr, 1), dtype='uint32', order='F')
        cur_srm = [False]
        cur_sm = {False: 0}

        for i in range(nr):
            has_one_string = False
            for j in range(nc):
                cur_code = a[i, j]
                if cur_code != 0:
                    cur_max_min = str_reverse_map[j][cur_code]
                    has_one_string = True
                    break
            for k in range(j, nc):
                cur_code = a[i, k]
                if cur_code != 0:
                    cur_val = str_reverse_map[k][cur_code]
                    if cur_val < cur_max_min:
                        cur_max_min = cur_val
            if has_one_string:
                if cur_max_min in cur_sm:
                    codes[i, 1] = cur_sm[cur_max_min]
                else:
                    codes[i, 1] = len(cur_sm)
                    cur_sm[cur_max_min] = len(cur_sm)
                    cur_srm.append(cur_max_min)
        new_str_reverse_map[0] = cur_srm
    return codes, new_str_reverse_map

def mean_int(ndarray[np.int64_t, ndim=2] a, axis, **kwargs):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        long *arr = <long*> a.data
        ndarray[np.int64_t] total

    if axis == 0:
        #return a.mean(0)
        total = np.zeros(nc, dtype=np.int64)
        for i in range(nc):
            for j in range(nr):
                total[i] += arr[i * nr + j]
        return total / nr
    else:
        #return a.mean(1)
        total = np.zeros(nr, dtype=np.int64)
        for i in range(nc):
            for j in range(nr):
                total[j] += arr[i * nr + j]
        return total / nc

def mean_bool(ndarray[np.uint8_t, ndim=2, cast=True] a, axis, **kwargs):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        unsigned char *arr = <unsigned char*> a.data
        ndarray[np.int64_t] total

    if axis == 0:
        total = np.zeros(nc, dtype='int64')
        for i in range(nc):
            for j in range(nr):
                total[i] += arr[i * nr + j]
        return total / nr
    else:
        total = np.zeros(nr, dtype='int64')
        for i in range(nc):
            for j in range(nr):
                total[j] += arr[i * nr + j]
        return total / nc

def mean_float(ndarray[np.float64_t, ndim=2] a, axis, hasnans):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1], ct = 0
        double *arr = <double*> a.data
        ndarray[np.float64_t] total

    if axis == 0:
        total = np.zeros(nc, dtype=np.float64)
        for i in range(nc):
            if hasnans[i] is None or hasnans[i]:
                ct = 0
                for j in range(nr):
                    if not isnan(arr[i * nr + j]):
                        total[i] += arr[i * nr + j]
                        ct += 1
                if ct != 0:
                    total[i] = total[i] / ct
                else:
                    total[i] = nan
            else:
                for j in range(nr):
                    total[i] += arr[i * nr + j]
                total[i] = total[i] / nr
    else:
        total = np.zeros(nr, dtype=np.float64)
        for i in range(nr):
            ct = 0
            for j in range(nc):
                if not isnan(arr[j * nr + i]):
                    total[i] += arr[j * nr + i]
                    ct += 1
            if ct != 0:
                total[i] = total[i] / ct
            else:
                total[i] = nan
    return total

def median_int(ndarray[np.int64_t, ndim=2] a, axis, **kwargs):
    cdef:
        Py_ssize_t i, nr = a.shape[0], nc = a.shape[1]
        np.float64_t first, second
        ndarray[np.float64_t] result

    if axis == 0:
        result = np.empty(nc, dtype='float64')
    else:
        result = np.empty(nr, dtype='float64')

    if axis == 0:
        if nr % 2 == 1:
            for i in range(nc):
                result[i] = quick_select_int2(a[:, i], nr, nr // 2)
        else:
            for i in range(nc):
                first = quick_select_int2(a[:, i], nr, nr // 2 - 1)
                second = quick_select_int2(a[:, i], nr, nr // 2)
                result[i] = (first + second) / 2
    else:
        if nc % 2 == 1:
            for i in range(nr):
                result[i] = quick_select_int2(a[i], nc, nc // 2)
        else:
            for i in range(nc):
                first = quick_select_int2(a[i], nc, nc // 2 - 1)
                second = quick_select_int2(a[i], nc, nc // 2)
                result[i] = (first + second) / 2
    return result

def median_bool(ndarray[np.uint8_t, cast=True, ndim=2] a, axis, **kwargs):
    # return np.median(a, axis=axis)
    return median_int(a.astype('int64'), axis=axis)

def median_float(ndarray[np.float64_t, ndim=2] a, axis, hasnans):
    if axis == 0:
        if hasnans.any():
            return bn.nanmedian(a, axis=0)
        return bn.median(a, axis=0)
    else:
        return bn.nanmedian(a, axis=1)

def median_int_1d(ndarray[np.int64_t] a):
    cdef:
        Py_ssize_t i, n = a.shape[0]
        np.float64_t first, second
        np.float64_t result

    if n % 2 == 1:
        result = quick_select_int2(a, n, n // 2)
    else:
        first = quick_select_int2(a, n, n // 2 - 1)
        second = quick_select_int2(a, n, n // 2)
        result = (first + second) / 2
    return result

def median_bool_1d(ndarray[np.uint8_t, cast=True] a):
    return median_int_1d(a.astype('int64'))

def median_float_1d(ndarray[np.float64_t] a, hasnans):
    if hasnans.any():
        return bn.nanmedian(a)
    return bn.median(a)

def var_float(ndarray[double, ndim=2] a, axis, int ddof, hasnans):
    cdef:
        Py_ssize_t i, j, i1
        double *x = <double*> a.data
        int ct = 0, n = len(a), nr = a.shape[0], nc = a.shape[1]
        ndarray[np.float64_t] total
        double K = nan, Ex = 0, Ex2 = 0

    if axis == 0:
        total = np.zeros(nc, dtype=np.float64)
        for i in range(nc):
            i1 = 0
            K = x[i * nr + i1]
            while isnan(K):
                i1 += 1
                K = x[i * nr + i1]
            Ex = 0
            Ex2 = 0
            ct = 0
            for j in range(i1, nr):
                if isnan(x[i * nr + j]):
                    continue
                ct += 1
                Ex += x[i * nr + j] - K
                Ex2 += (x[i * nr + j] - K) * (x[i * nr + j] - K)
            if ct <= ddof:
                total[i] = nan
            else:
                total[i] = (Ex2 - (Ex * Ex) / ct) / (ct - ddof)
    else:
        total = np.zeros(nr, dtype=np.float64)
        for i in range(nr):
            i1 = 0
            K = x[i1 * nr + i]
            while isnan(K):
                i1 += 1
                K = x[i1 * nr + i]
            Ex = 0
            Ex2 = 0
            ct = 0
            for j in range(i1, nc):
                if isnan(x[j * nr + i]):
                    continue
                ct += 1
                Ex += x[j * nr + i] - K
                Ex2 += (x[j * nr + i] - K) * (x[j * nr + i] - K)
            if ct <= ddof:
                total[i] = nan
            else:
                total[i] = (Ex2 - (Ex * Ex) / ct) / (ct - ddof)

    return total

def var_int(ndarray[np.int64_t, ndim=2] a, axis, int ddof, hasnans):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        long *x = <long*> a.data
        ndarray[np.float64_t] total
        double K, Ex = 0, Ex2 = 0

    if axis == 0:
        total = np.zeros(nc, dtype=np.float64)
        for i in range(nc):
            if nr <= ddof:
                total[i] = nan
                continue
            K = x[i * nr]
            Ex = 0
            Ex2 = 0
            for j in range(nr):
                Ex += x[i * nr + j] - K
                Ex2 += (x[i * nr + j] - K) * (x[i * nr + j] - K)
            
            total[i] = (Ex2 - (Ex * Ex) / nr) / (nr - ddof)
    else:
        total = np.zeros(nr, dtype=np.float64)
        for i in range(nr):
            if nc <= ddof:
                total[i] = nan
                continue
            K = x[i]
            Ex = 0
            Ex2 = 0
            for j in range(nc):
                Ex += x[j * nr + i] - K
                Ex2 += (x[j * nr + i] - K) * (x[j * nr + i] - K)
            
            total[i] = (Ex2 - (Ex * Ex) / nc) / (nc - ddof)
    return total

def var_bool(ndarray[np.uint8_t, ndim=2, cast=True] a, axis, int ddof, hasnans):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        unsigned char *x = <unsigned char *> a.data
        ndarray[np.float64_t] total
        double K, Ex = 0, Ex2 = 0

    if axis == 0:
        total = np.zeros(nc, dtype=np.float64)
        for i in range(nc):
            if nr <= ddof:
                total[i] = nan
                continue
            K = x[i * nr]
            Ex = 0
            Ex2 = 0
            for j in range(nr):
                Ex += x[i * nr + j] - K
                Ex2 += (x[i * nr + j] - K) * (x[i * nr + j] - K)
            
            total[i] = (Ex2 - (Ex * Ex) / nr) / (nr - ddof)
    else:
        total = np.zeros(nr, dtype=np.float64)
        for i in range(nr):
            if nc <= ddof:
                total[i] = nan
                continue
            K = x[i]
            Ex = 0
            Ex2 = 0
            for j in range(nc):
                Ex += x[j * nr + i] - K
                Ex2 += (x[j * nr + i] - K) * (x[j * nr + i] - K)
            
            total[i] = (Ex2 - (Ex * Ex) / nc) / (nc - ddof)
    return total

def std_float(ndarray[np.float64_t, ndim=2] a, axis, int ddof, hasnans):
    return np.sqrt(var_float(a, axis, ddof, hasnans))

def std_int(ndarray[np.int64_t, ndim=2] a, axis, int ddof, hasnans):
    return np.sqrt(var_int(a, axis, ddof, hasnans))

def std_bool(ndarray[np.uint8_t, cast=True, ndim=2] a, axis, int ddof, hasnans):
    return np.sqrt(var_bool(a, axis, ddof, hasnans))

def any_int(ndarray[np.int64_t, ndim=2] a, axis, hasnans):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        ndarray[np.uint8_t, cast=True] result

    if axis == 0:
        result = np.full(nc, False, dtype='bool')
        for i in range(nc):
            for j in range(nr):
                if a[j, i] != 0:
                    result[i] = True
                    break
    else:
        result = np.full(nr, False, dtype='bool')
        for i in range(nr):
            for j in range(nc):
                if a[i, j] != 0:
                    result[i] = True
                    break
    return result

def any_bool(ndarray[np.uint8_t, ndim=2, cast=True] a, axis, hasnans):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        ndarray[np.uint8_t, cast=True] result

    if axis == 0:
        result = np.full(nc, False, dtype='bool')
        for i in range(nc):
            for j in range(nr):
                if a[j, i] == True:
                    result[i] = True
                    break
    else:
        result = np.full(nr, False, dtype='bool')
        for i in range(nr):
            for j in range(nc):
                if a[i, j] == True:
                    result[i] = True
                    break
    return result

def any_float(ndarray[np.float64_t, ndim=2] a, axis, hasnans):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        ndarray[np.uint8_t, cast=True] result

    if axis == 0:
        result = np.full(nc, False, dtype='bool')
        for i in range(nc):
            for j in range(nr):
                if a[j, i] != 0 and not isnan(a[j, i]):
                    result[i] = True
                    break
    else:
        result = np.full(nr, False, dtype='bool')
        for i in range(nr):
            for j in range(nc):
                if a[i, j] != 0 and not isnan(a[i, j]):
                    result[i] = True
                    break
    return result

def any_str(ndarray[np.uint32_t, ndim=2] a, dict str_reverse_map, axis, hasnans, **kwargs):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1], num_vals
        list cur_srm
        ndarray[np.uint8_t, cast=True] result

    if axis == 0:
        result = np.full(nc, False, dtype='bool')
        for i in range(nc):
            cur_srm = str_reverse_map[i]
            num_vals = len(cur_srm)
            for j in range(1, num_vals):
                if cur_srm[j] != '':
                    result[i] = True
                    break
    else:
        result = np.full(nr, False, dtype='bool')
        for i in range(nr):
            for j in range(nc):
                if a[i, j] != 0 and str_reverse_map[a[i, j]] != '':
                    result[i] = True
                    break
    return result

def all_int(ndarray[np.int64_t, ndim=2] a, axis, hasnans):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        ndarray[np.uint8_t, cast=True] result
    if axis == 0:
        result = np.full(nc, True, dtype='bool')
        for i in range(nc):
            for j in range(nr):
                if a[j, i] == 0:
                    result[i] = False
                    break
    else:
        result = np.full(nr, True, dtype='bool')
        for i in range(nr):
            for j in range(nc):
                if a[i, j] == 0:
                    result[i] = False
                    break
    return result

def all_bool(ndarray[np.uint8_t, ndim=2, cast=True] a, axis, hasnans):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        ndarray[np.uint8_t, cast=True] result

    if axis == 0:
        result = np.full(nc, True, dtype='bool')
        for i in range(nc):
            for j in range(nr):
                if a[j, i] == False:
                    result[i] = False
                    break
    else:
        result = np.full(nr, True, dtype='bool')
        for i in range(nr):
            for j in range(nc):
                if a[i, j] == False:
                    result[i] = False
                    break
    return result

def all_float(ndarray[np.float64_t, ndim=2] a, axis, hasnans):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        ndarray[np.uint8_t, cast=True] result

    if axis == 0:
        result = np.full(nc, True, dtype='bool')
        for i in range(nc):
            for j in range(nr):
                if a[j, i] == 0 or isnan(a[j, i]):
                    result[i] = False
                    break
    else:
        result = np.full(nr, True, dtype='bool')
        for i in range(nr):
            for j in range(nc):
                if a[i, j] == 0 or isnan(a[i, j]):
                    result[i] = False
                    break
    return result

def all_str(ndarray[np.uint32_t, ndim=2] a, dict str_reverse_map, axis, hasnans, **kwargs):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1], num_vals
        list cur_srm
        ndarray[np.uint8_t, cast=True] result

    if axis == 0:
        result = np.full(nc, True, dtype='bool')
        for i in range(nc):
            cur_srm = str_reverse_map[i]
            num_vals = len(cur_srm)
            for j in range(1, num_vals):
                if cur_srm[j] == '':
                    result[i] = False
                    break
    else:
        result = np.full(nr, True, dtype='bool')
        for i in range(nr):
            for j in range(nc):
                if a[i, j] == 0 or str_reverse_map[a[i, j]] == '':
                    result[i] = False
                    break
    return result

def argmax_int(ndarray[np.int64_t, ndim=2] a, axis, hasnans):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        long *arr = <long*> a.data
        long amax
        ndarray[np.int64_t] result

    if axis == 0:
        result = np.zeros(nc, dtype=np.int64)
        for i in range(nc):
            amax = arr[i * nr] 
            for j in range(nr):
                if arr[i * nr + j] > amax:
                    amax = arr[i * nr + j]
                    result[i] = j
    else:
        result = np.zeros(nr, dtype=np.int64)
        for i in range(nr):
            amax = arr[i] 
            for j in range(nc):
                if arr[j * nr + i] > amax:
                    amax = arr[j * nr + i]
                    result[i] = j
    return result

def argmin_int(ndarray[np.int64_t, ndim=2] a, axis, hasnans):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        long *arr = <long*> a.data
        long amin
        ndarray[np.int64_t] result

    if axis == 0:
        result = np.zeros(nc, dtype=np.int64)
        for i in range(nc):
            amin = arr[i * nr]
            for j in range(nr):
                if arr[i * nr + j] < amin:
                    amin = arr[i * nr + j]
                    result[i] = j
    else:
        result = np.zeros(nr, dtype=np.int64)
        for i in range(nr):
            amin = arr[i] 
            for j in range(nc):
                if arr[j * nr + i] < amin:
                    amin = arr[j * nr + i]
                    result[i] = j
    return result

def argmax_bool(ndarray[np.uint8_t, cast=True, ndim=2] a, axis, hasnans):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        unsigned char *arr = <unsigned char*> a.data
        ndarray[np.int64_t] result

    if axis == 0:
        result = np.zeros(nc, dtype=np.int64)
        for i in range(nc):
            for j in range(nr):
                if arr[i * nr + j]  == True:
                    result[i] = j
                    break
    else:
        result = np.zeros(nr, dtype=np.int64)
        for i in range(nr):
            for j in range(nc):
                if arr[j * nr + i]  == True:
                    result[i] = j
                    break
    return result

def argmin_bool(ndarray[np.uint8_t, cast=True, ndim=2] a, axis, hasnans):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        unsigned char *arr = <unsigned char*> a.data
        ndarray[np.int64_t] result

    if axis == 0:
        result = np.zeros(nc, dtype=np.int64)
        for i in range(nc):
            for j in range(nr):
                if arr[i * nr + j]  == False:
                    result[i] = j
                    break
    else:
        result = np.zeros(nr, dtype=np.int64)
        for i in range(nr):
            for j in range(nc):
                if arr[j * nr + i]  == False:
                    result[i] = j
                    break
    return result

def argmax_float(ndarray[np.float64_t, ndim=2] a, axis, hasnans):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        double *arr = <double*> a.data
        long iloc = -1
        double amax
        ndarray[np.float64_t] result

    if axis == 0:
        result = np.empty(nc, dtype=np.float64)
        for i in range(nc):
            amax = MIN_FLOAT
            for j in range(nr):
                if arr[i * nr + j] > amax:
                    amax = arr[i * nr + j]
                    iloc = j
            if amax <= MIN_FLOAT + 1:
                result[i] = np.nan
            else:
                result[i] = iloc
    else:
        result = np.empty(nr, dtype=np.float64)
        for i in range(nr):
            amax = MIN_FLOAT
            for j in range(nc):
                if arr[j * nr + i] > amax:
                    amax = arr[j * nr + i]
                    iloc = j
            if amax <= MIN_FLOAT + 1:
                result[i] = np.nan
            else:
                result[i] = iloc

    if (result % 1).sum() == 0:
        return result.astype('int64')
    return result

def argmin_float(ndarray[np.float64_t, ndim=2] a, axis, hasnans):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        double *arr = <double*> a.data
        long iloc = -1
        double amin
        ndarray[np.float64_t] result

    if axis == 0:
        result = np.empty(nc, dtype=np.float64)
        for i in range(nc):
            amin = MAX_FLOAT
            for j in range(nr):
                if arr[i * nr + j] < amin:
                    amin = arr[i * nr + j]
                    iloc = j
            if amin >= MAX_FLOAT - 1:
                result[i] = np.nan
            else:
                result[i] = iloc
    else:
        result = np.empty(nr, dtype=np.float64)
        for i in range(nr):
            amin = MAX_FLOAT
            for j in range(nc):
                if arr[j * nr + i] < amin:
                    amin = arr[j * nr + i]
                    iloc = j
            if amin >= MAX_FLOAT - 1:
                result[i] = np.nan
            else:
                result[i] = iloc

    if (result % 1).sum() == 0:
        return result.astype('int64')
    return result

def argmax_str(ndarray[np.uint32_t, ndim=2] a, dict str_reverse_map, axis, hasnans, **kwargs):
    cdef:
        Py_ssize_t i, j, k
        int nr = a.shape[0], nc = a.shape[1], num_vals
        list cur_srm
        np.uint32_t max_code
        str cur_max_min
        ndarray[np.int64_t] result

    if axis == 0:
        result = np.empty(nc, 'int64', 'F')
        for i in range(nc):
            cur_srm = str_reverse_map[i]
            num_vals = len(cur_srm)
            if num_vals == 1:
                result[i] = np.nan
                continue
            else:
                cur_max_min = cur_srm[1]
                max_code = 1
                for j in range(2, num_vals):
                    cur_val = cur_srm[j]
                    if cur_val > cur_max_min:
                        cur_max_min = cur_val
                        max_code = j
            for j in range(nr):
                if max_code == a[j, i]:
                    result[i] = j
                    break
    else:
        pass

    return result

def argmin_str(ndarray[np.uint32_t, ndim=2] a, dict str_reverse_map, axis, hasnans, **kwargs):
    cdef:
        Py_ssize_t i, j, k
        int nr = a.shape[0], nc = a.shape[1], num_vals
        list cur_srm
        np.uint32_t max_code
        str cur_max_min
        ndarray[np.int64_t] result

    if axis == 0:
        result = np.empty(nc, 'int64', 'F')
        for i in range(nc):
            cur_srm = str_reverse_map[i]
            num_vals = len(cur_srm)
            if num_vals == 1:
                result[i] = np.nan
                continue
            else:
                cur_max_min = cur_srm[1]
                max_code = 1
                for j in range(2, num_vals):
                    cur_val = cur_srm[j]
                    if cur_val < cur_max_min:
                        cur_max_min = cur_val
                        max_code = j
            for j in range(nr):
                if max_code == a[j, i]:
                    result[i] = j
                    break
    else:
        pass

    return result

def count_int(ndarray[np.int64_t, ndim=2] a, axis, hasnans):
    if axis == 0:
        result = np.full(a.shape[1], a.shape[0], dtype=np.int64)
    else:
        result = np.full(a.shape[0], a.shape[1], dtype=np.int64)
    return result

def count_bool(ndarray[np.uint8_t, cast=True, ndim=2] a, axis, hasnans):
    if axis == 0:
        result = np.full(a.shape[1], a.shape[0], dtype=np.int64)
    else:
        result = np.full(a.shape[0], a.shape[1], dtype=np.int64)
    return result

def count_float(ndarray[np.float64_t, ndim=2] a, axis, hasnans):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        double *arr = <double*> a.data
        long ct
        ndarray[np.int64_t] result

    if axis == 0:
        result = np.zeros(nc, dtype=np.int64)
        for i in range(nc):
            ct = 0
            for j in range(nr):
                if not isnan(arr[i * nr + j]):
                    ct += 1
            result[i] = ct
    else:
        result = np.zeros(nr, dtype=np.int64)
        for i in range(nr):
            ct = 0
            for j in range(nc):
                if not isnan(arr[j * nr + i]):
                    ct += 1
            result[i] = ct
    return result
            
def count_str(ndarray[np.uint32_t, ndim=2] a, dict str_reverse_map, axis, hasnans, **kwargs):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1], num_vals
        list cur_srm
        ndarray[np.int64_t] result

    if axis == 0:
        result = np.full(nc, nr, dtype=np.int64)
        for i in range(nc):
            if hasnans[i] is None or hasnans[i]:
                result[i] = nr - (a[:, i] == 0).sum()
    else:
        result = np.zeros(nr, dtype=np.int64)
        for i in range(nr):
            ct = 0
            for j in range(nc):
                if a[i, j] != 0:
                    ct += 1
            result[i] = ct
    return result

def clip_str_lower(ndarray[object, ndim=2] a, str lower):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        ndarray[object, ndim=2] b = np.empty((nr, nc), dtype='O')

    hasnans = True
    if hasnans == True or hasnans is None:
        for i in range(nc):
            for j in range(nr):
                if a[j, i] is None:
                    b[j, i] = None
                else:
                    if a[j, i] < lower:
                        b[j, i] = lower
                    else:
                        b[j, i] = a[j, i]
        return b
    return a.clip(lower)

def clip_str_upper(ndarray[object, ndim=2] a, str upper):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        ndarray[object, ndim=2] b = np.empty((nr, nc), dtype='O')

    hasnans = True
    if hasnans == True or hasnans is None:
        for i in range(nc):
            for j in range(nr):
                if a[j, i] is None:
                    b[j, i] = None
                else:
                    if a[j, i] > upper:
                        b[j, i] = upper
                    else:
                        b[j, i] = a[j, i]
        return b
    return a.clip(max=upper)

def clip_str_both(ndarray[object, ndim=2] a, str lower, str upper):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        ndarray[object, ndim=2] b = np.empty((nr, nc), dtype='O')

    hasnans = True
    if hasnans == True or hasnans is None:
        for i in range(nc):
            for j in range(nr):
                if a[j, i] is None:
                    b[j, i] = None
                else:
                    if a[j, i] < lower:
                        b[j, i] = lower
                    elif a[j, i] > upper:
                        b[j, i] = upper
                    else:
                        b[j, i] = a[j, i]
        return b
    return a.clip(lower, upper)

def cummax_float(ndarray[np.float64_t, ndim=2] a, axis, hasnans):
    cdef:
        Py_ssize_t i, j, k = 0
        int nr = a.shape[0], nc = a.shape[1]
        np.float64_t *arr = <np.float64_t*> a.data
        np.float64_t amax
        ndarray[np.float64_t, ndim=2] b

    if axis == 0:
        b = np.empty((nr, nc), dtype=np.float64, order='F')
        for i in range(nc):
            k = 0
            amax = arr[i * nr + k]
            b[k, i] = amax
            while isnan(amax) and k < nr - 1:
                k += 1
                amax = arr[i * nr + k]
                b[k, i] = nan
            for j in range(k, nr):
                if arr[i * nr + j] > amax:
                    amax = arr[i * nr + j]
                b[j, i] = amax
    else:
        b = np.empty((nr, nc), dtype=np.float64, order='F')
        for i in range(nr):
            k = 0
            amax = arr[k * nr + i]
            b[i, k] = amax
            while isnan(amax) and k < nc - 1:
                k += 1
                amax = arr[k * nr + i]
                b[i, k] = nan
            for j in range(k, nc):
                if arr[j * nr + i] > amax:
                    amax = arr[j * nr + i]
                b[i, j] = amax
    return b

def cummin_float(ndarray[np.float64_t, ndim=2] a, axis, hasnans):
    cdef:
        Py_ssize_t i, j, k = 0
        int nr = a.shape[0], nc = a.shape[1]
        np.float64_t *arr = <np.float64_t*> a.data
        np.float64_t amin
        ndarray[np.float64_t, ndim=2] b

    if axis == 0:
        b = np.empty((nr, nc), dtype=np.float64, order='F')
        for i in range(nc):
            k = 0
            amin = arr[i * nr + k]
            b[k, i] = amin
            while isnan(amin) and k < nr - 1:
                k += 1
                amin = arr[i * nr + k]
                b[k, i] = nan
            for j in range(k, nr):
                if arr[i * nr + j] < amin:
                    amin = arr[i * nr + j]
                b[j, i] = amin
    else:
        b = np.empty((nr, nc), dtype=np.float64, order='F')
        for i in range(nr):
            k = 0
            amin = arr[k * nr + i]
            b[i, k] = amin
            while isnan(amin) and k < nc - 1:
                k += 1
                amin = arr[k * nr + i]
                b[i, k] = nan
            for j in range(k, nc):
                if arr[j * nr + i] < amin:
                    amin = arr[j * nr + i]
                b[i, j] = amin
    return b

def cummax_int(ndarray[np.int64_t, ndim=2] a, axis, hasnans):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        np.int64_t *arr = <np.int64_t*> a.data
        np.int64_t amax
        ndarray[np.int64_t, ndim=2] b = np.empty((nr, nc), dtype=np.int64)

    if axis == 0:
        b = np.empty((nr, nc), dtype=np.int64)
        for i in range(nc):
            amax = arr[i * nr]
            for j in range(nr):
                if arr[i * nr + j] > amax:
                    amax = arr[i * nr + j]
                b[j, i] = amax
    else:
        b = np.empty((nr, nc), dtype=np.int64)
        for i in range(nr):
            amax = arr[i]
            for j in range(nc):
                if arr[j * nr + i] > amax:
                    amax = arr[j * nr + i]
                b[i, j] = amax
    return b

def cummin_int(ndarray[np.int64_t, ndim=2] a, axis, hasnans):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        np.int64_t *arr = <np.int64_t*> a.data
        np.int64_t amin
        ndarray[np.int64_t, ndim=2] b = np.empty((nr, nc), dtype=np.int64)

    if axis == 0:
        b = np.empty((nr, nc), dtype=np.int64)
        for i in range(nc):
            amin = arr[i * nr]
            for j in range(nr):
                if arr[i * nr + j] < amin:
                    amin = arr[i * nr + j]
                b[j, i] = amin
    else:
        b = np.empty((nr, nc), dtype=np.int64)
        for i in range(nr):
            amin = arr[i]
            for j in range(nc):
                if arr[j * nr + i] < amin:
                    amin = arr[j * nr + i]
                b[i, j] = amin
    return b

def cummax_bool(ndarray[np.uint8_t, cast=True, ndim=2] a, axis, hasnans):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1], amax = 0
        unsigned char *arr = <unsigned char*> a.data
        ndarray[np.uint8_t, ndim=2, cast=True] b

    if axis == 0:
        for i in range(nc):
            b = np.empty((nr, nc), dtype='bool')
            amax = False
            for j in range(nr):
                if amax == True:
                    b[j, i] = True
                elif arr[i * nr + j] == True:
                    amax = True
                    b[j, i] = True
                else:
                    b[j, i] = False
    else:
        for i in range(nr):
            b = np.empty((nr, nc), dtype='bool')
            amax = False
            for j in range(nc):
                if amax == True:
                    b[i, j] = True
                elif arr[j * nr + i] == True:
                    amax = True
                    b[i, j] = True
                else:
                    b[i, j] = False
    return b

def cummin_bool(ndarray[np.uint8_t, cast=True, ndim=2] a, axis, hasnans):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1], amin = 0
        unsigned char *arr = <unsigned char*> a.data
        ndarray[np.uint8_t, ndim=2, cast=True] b

    if axis == 0:
        for i in range(nc):
            b = np.empty((nr, nc), dtype='bool')
            amin = True
            for j in range(nr):
                if not amin:
                    b[j, i] = False
                elif not arr[i * nr + j]:
                    amin = False
                    b[j, i] = False
                else:
                    b[j, i] = True
    else:
        for i in range(nr):
            b = np.empty((nr, nc), dtype='bool')
            amin = True
            for j in range(nc):
                if not amin:
                    b[i, j] = False
                elif not arr[j * nr + i]:
                    amin = False
                    b[i, j] = False
                else:
                    b[i, j] = True
    return b

def cummax_str(ndarray[np.uint32_t, ndim=2] a, dict str_reverse_map, axis, hasnans, **kwargs):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1], k, cur_code
        list cur_srm
        np.uint32_t cur_max_code
        str cur_max, cur_val
        dict new_str_reverse_map = {}
        list new_srm
        ndarray[np.uint32_t, ndim=2] result = np.empty((nr, nc), 'uint32', 'F')

    if axis == 0:
        for i in range(nc):
            cur_srm = str_reverse_map[i]
            new_srm = [False]
            if hasnans[i] is None or hasnans[i]:
                cur_max_code = 0
                k = 0
                while k < nr and cur_max_code == 0:
                    cur_code =  a[k, i]
                    if cur_code != 0:
                        cur_val = cur_srm[cur_code]
                        new_srm.append(cur_val)
                        cur_max = cur_val
                        cur_max_code = 1
                    result[k, i] = cur_max_code
                    k += 1

                for j in range(k, nr):
                    cur_code = a[j, i]
                    if cur_code != 0:
                        cur_val = cur_srm[cur_code]
                        if  cur_val > cur_max:
                            cur_max = cur_val
                            new_srm.append(cur_max)
                            cur_max_code += 1
                    result[j, i] = cur_max_code
            new_str_reverse_map[i] = new_srm
    else:
        pass
    return result, new_str_reverse_map

def cummin_str(ndarray[np.uint32_t, ndim=2] a, dict str_reverse_map, axis, hasnans, **kwargs):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1], k, cur_code
        list cur_srm
        np.uint32_t cur_max_code
        str cur_max, cur_val
        dict new_str_reverse_map = {}
        list new_srm
        ndarray[np.uint32_t, ndim=2] result = np.empty((nr, nc), 'uint32', 'F')

    if axis == 0:
        for i in range(nc):
            cur_srm = str_reverse_map[i]
            new_srm = [False]
            if hasnans[i] is None or hasnans[i]:
                cur_max_code = 0
                k = 0
                while k < nr and cur_max_code == 0:
                    cur_code =  a[k, i]
                    if cur_code != 0:
                        cur_val = cur_srm[cur_code]
                        new_srm.append(cur_val)
                        cur_max = cur_val
                        cur_max_code = 1
                    result[k, i] = cur_max_code
                    k += 1

                for j in range(k, nr):
                    cur_code = a[j, i]
                    if cur_code != 0:
                        cur_val = cur_srm[cur_code]
                        if  cur_val < cur_max:
                            cur_max = cur_val
                            new_srm.append(cur_max)
                            cur_max_code += 1
                    result[j, i] = cur_max_code
            new_str_reverse_map[i] = new_srm
    else:
        pass
    return result, new_str_reverse_map

def cumsum_float(ndarray[np.float64_t, ndim=2] a, axis, hasnans):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        np.float64_t *arr = <np.float64_t*> a.data
        ndarray[np.float64_t, ndim=2] total = np.zeros((nr, nc), dtype=np.float64)
        double cur_total = 0

    if axis == 0:
        for i in range(nc):
            cur_total = 0
            for j in range(nr):
                if not isnan(arr[i * nr + j]):
                    cur_total += arr[i * nr + j]
                total[j, i] = cur_total
    else:
        for i in range(nr):
            cur_total = 0
            for j in range(nc):
                if not isnan(arr[j * nr + i]):
                    cur_total += arr[j * nr + i]
                total[i, j] = cur_total
    return total

def cumsum_int(ndarray[np.int64_t, ndim=2] a, axis, hasnans):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        np.int64_t *arr = <np.int64_t*> a.data
        ndarray[np.int64_t, ndim=2] total = np.empty((nr, nc), dtype=np.int64)
        np.int64_t cur_total

    if axis == 0:
        for i in range(nc):
            cur_total = 0
            for j in range(nr):
                cur_total += arr[i * nr + j]
                total[j, i] = cur_total
    else:
        for i in range(nr):
            cur_total = 0
            for j in range(nc):
                cur_total += arr[j * nr + i]
                total[i, j] = cur_total
    return total

def cumsum_bool(ndarray[np.int8_t, ndim=2, cast=True] a, axis, hasnans):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        np.int8_t *arr = <np.int8_t*> a.data
        ndarray[np.int64_t, ndim=2] total = np.empty((nr, nc), dtype=np.int64)
        np.int64_t cur_total

    if axis == 0:
        for i in range(nc):
            cur_total = 0
            for j in range(nr):
                cur_total += arr[i * nr + j]
                total[j, i] = cur_total
    else:
        for i in range(nr):
            cur_total = 0
            for j in range(nc):
                cur_total += arr[j * nr + i]
                total[i, j] = cur_total
    return total

def cumsum_str(ndarray[np.uint32_t, ndim=2] a, dict str_reverse_map, axis, hasnans, **kwargs):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1], ct, cur_code
        list cur_srm
        ndarray[np.uint32_t, ndim=2] result = np.empty((nr, nc), 'uint32', 'F')
        str cur_max, cur_val, total
        dict new_str_reverse_map = {}
        list new_srm
        bint contains_nan, contains_empty_str
        int empty_str_loc, nan_str_loc

    if axis == 0:
        for i in range(nc):
            cur_srm = str_reverse_map[i]
            total = ''
            new_srm = [False]
            new_str_reverse_map[i] = new_srm
            ct = 1
            contains_nan = False
            contains_empty_str = False
            empty_str_loc = 0
            if hasnans[i] is None or hasnans[i]:
                for j in range(nr):
                    cur_code = a[j, i]
                    if cur_code != 0:
                        cur_val = cur_srm[cur_code]
                        if cur_val == '':
                            if not contains_empty_str:
                                result[j, i] = ct
                                contains_empty_str = True
                                cur_srm.append('')
                                ct += 1
                            else:
                                result[j, i] = ct - 1
                        else:
                            result[j, i] = ct
                            total += cur_val
                            new_srm.append(total)
                            ct += 1
                    else:
                        result[j, i] = 0
            else:
                pass
    else:
        pass
    return result, new_str_reverse_map


def cumprod_float(ndarray[np.float64_t, ndim=2] a, axis, hasnans):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        np.float64_t *arr = <np.float64_t*> a.data
        ndarray[np.float64_t, ndim=2] total = np.zeros((nr, nc), dtype=np.float64)
        double cur_total = 0

    if axis == 0:
        for i in range(nc):
            cur_total = 1
            for j in range(nr):
                if not isnan(arr[i * nr + j]):
                    cur_total *= arr[i * nr + j]
                total[j, i] = cur_total
    else:
        for i in range(nr):
            cur_total = 1
            for j in range(nc):
                if not isnan(arr[j * nr + i]):
                    cur_total *= arr[j * nr + i]
                total[i, j] = cur_total
    return total

def cumprod_int(ndarray[np.int64_t, ndim=2] a, axis, hasnans):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        np.int64_t *arr = <np.int64_t*> a.data
        ndarray[np.int64_t, ndim=2] total = np.empty((nr, nc), dtype=np.int64)
        np.int64_t cur_total

    if axis == 0:
        for i in range(nc):
            cur_total = 1
            for j in range(nr):
                cur_total *= arr[i * nr + j]
                total[j, i] = cur_total
    else:
        for i in range(nr):
            cur_total = 1
            for j in range(nc):
                cur_total *= arr[j * nr + i]
                total[i, j] = cur_total
    return total

def cumprod_bool(ndarray[np.int8_t, ndim=2, cast=True] a, axis, hasnans):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        np.int8_t *arr = <np.int8_t*> a.data
        ndarray[np.int64_t, ndim=2] total = np.empty((nr, nc), dtype=np.int64)
        np.int64_t cur_total

    if axis == 0:
        for i in range(nc):
            cur_total = 1
            for j in range(nr):
                cur_total *= arr[i * nr + j]
                total[j, i] = cur_total
    else:
        for i in range(nr):
            cur_total = 1
            for j in range(nc):
                cur_total *= arr[j * nr + i]
                total[i, j] = cur_total
    return total

def isna_str(ndarray[np.uint32_t, ndim=2] a, dict str_reverse_map, hasnans, **kwargs):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        list cur_srm

    for i in range(nc):
        if hasnans[i] is None or hasnans[i]:
            return a == 0
        else:
            return np.zeros((nr, nc), dtype='bool')

def isna_float(ndarray[np.float64_t, ndim=2] a, ndarray[np.uint8_t, cast=True] hasnans):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
    # slower than numpy
        np.float64_t *arr = <np.float64_t*> a.data
        ndarray[np.int8_t, cast=True, ndim=2] b = np.zeros((nr, nc), dtype=bool)
    for i in range(nc):
        if hasnans[i] is False:
            continue
        for j in range(nr):
            b[j, i] = isnan(arr[i * nr + j])
    return b

def get_first_non_nan(ndarray[np.float64_t, ndim=2] a):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1]
        ndarray[np.float64_t] result = np.full(nc, nan)

    for i in range(nc):
        for j in range(nr):
            if not isnan(a[j, i]):
                result[i] = a[j, i]
                break
    return result

def get_quantile_float(ndarray[np.float64_t] a, double percent):
    cdef:
        double k = (len(a) - 1) * percent, d0, d1
        int f, c

    f = <int> floor(k)
    c = <int> ceil(k)
    if f == c:
        return a[f]
    d0 = a[f] * (c - k)
    d1 = a[c] * (k - f)
    return d0 + d1

def quantile_float(ndarray[np.float64_t, ndim=2] a, axis, double q,
                   ndarray[np.uint8_t, cast=True] hasnans):
    cdef:
        int i, n
        ndarray[np.int64_t] count
        ndarray[np.float64_t] b

    count = (~np.isnan(a)).sum(axis)
    if count.sum() == a.size:
        return np.percentile(a, q * 100, axis)

    a = np.sort(a, axis=axis)
    n = len(count)
    b = np.empty(n, dtype='float64')
    if axis == 0:
        for i in range(n):
            if count[i] == 0:
                b[i] = nan
            elif count[i] == 1:
                b[i] = a[0, i]
            else:
                b[i] = get_quantile_float(a[:count[i], i], q)
    else:
        for i in range(n):
            if count[i] == 0:
                b[i] = nan
            elif count[i] == 1:
                b[i] = a[i, 0]
            else:
                b[i] = get_quantile_float(a[i, :count[i]], q)

    return b

def quantile_int(ndarray[np.int64_t, ndim=2] a, axis, double q,
                 ndarray[np.uint8_t, cast=True] hasnans):
    return np.percentile(a, q * 100, axis)

def quantile_bool(ndarray[np.uint8_t, ndim=2, cast=True] a, axis, double q,
                  ndarray[np.uint8_t, cast=True] hasnans):
    return np.percentile(a, q * 100, axis)

# def fillna_float(ndarray[np.float64_t, ndim=2] a, int limit, np.float64_t value):
#         i, j, k, ct
#         nr = a.shape[0]
#         nc = a.shape[1]
#         ndarray[np.float64_t, ndim=2] a_new = np.empty((nr, nc), dtype='float64')
#
#     if limit == -1:
#         for i in range(nc):
#             for j in range(nr):
#                 if isnan(a[j, i]):
#                     a_new[j, i] = value
#                 else:
#                     a_new[j, i] = a[j, i]
#     else:
#         for i in range(nc):
#             ct = 0
#             for j in range(nr):
#                 if isnan(a[j, i]):
#                     a_new[j, i] = value
#                     ct += 1
#                 else:
#                     a_new[j, i] = a[j, i]
#                 if ct == limit:
#                     for k in range(j + 1, nr):
#                         a_new[k, i] = a[k, i]
#                     break
#     return a_new
#
# def fillna_str(ndarray[object, ndim=2] a, int limit, str value):
#         i, j, k, ct
#         nr = a.shape[0]
#         nc = a.shape[1]
#         ndarray[object, ndim=2] a_new = np.empty((nr, nc), dtype='O')
#
#     if limit == -1:
#         for i in range(nc):
#             for j in range(nr):
#                 if a[j, i] is None:
#                     a_new[j, i] = value
#                 else:
#                     a_new[j, i] = a[j, i]
#     else:
#         for i in range(nc):
#             ct = 0
#             for j in range(nr):
#                 if a[j, i] is None:
#                     a_new[j, i] = value
#                     ct += 1
#                 else:
#                     a_new[j, i] = a[j, i]
#                 if ct == limit:
#                     for k in range(j + 1, nr):
#                         a_new[k, i] = a[k, i]
#                     break
#     return a_new

def ffill_float(ndarray[np.float64_t, ndim=2] a, int limit):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1], ct = 0

    if limit == -1:
        for i in range(nc):
            for j in range(1, nr):
                if isnan(a[j, i]):
                    a[j, i] = a[j - 1, i]
    else:
        for i in range(nc):
            for j in range(1, nr):
                if isnan(a[j, i]):
                    if ct == limit:
                        continue
                    a[j, i] = a[j - 1, i]
                    ct += 1
                else:
                    ct = 0
    return a

def ffill_str(ndarray[np.uint32_t, ndim=2] a, dict str_reverse_map, int limit, hasnans, **kwargs):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1], ct = 0
    if limit == -1:
        for i in range(nc):
            for j in range(1, nr):
                if a[j, i] is None:
                    a[j, i] = a[j - 1, i]
    else:
        for i in range(nc):
            for j in range(1, nr):
                if a[j, i] is None:
                    if ct == limit:
                        continue
                    a[j, i] = a[j - 1, i]
                    ct += 1
                else:
                    ct = 0
    return a

def bfill_float(ndarray[np.float64_t, ndim=2] a, int limit):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1], ct = 0

    if limit == -1:
        for i in range(nc):
            for j in range(nr - 2, -1, -1):
                if isnan(a[j, i]):
                    a[j, i] = a[j + 1, i]
    else:
        for i in range(nc):
            for j in range(nr - 2, -1, -1):
                if isnan(a[j, i]):
                    if ct == limit:
                        continue
                    a[j, i] = a[j + 1, i]
                    ct += 1
                else:
                    ct = 0
    return a

def bfill_str(ndarray[object, ndim=2] a, int limit):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1], ct = 0
    if limit == -1:
        for i in range(nc):
            for j in range(nr - 2, -1, -1):
                if a[j, i] is None:
                    a[j, i] = a[j + 1, i]
    else:
        for i in range(nc):
            for j in range(nr - 2, -1, -1):
                if a[j, i] is None:
                    if ct == limit:
                        continue
                    a[j, i] = a[j + 1, i]
                    ct += 1
                else:
                    ct = 0
    return a

def ffill_date(ndarray[np.int64_t, ndim=2] a, int limit, ndarray[np.uint8_t, cast=True, ndim=2] nans):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1], ct = 0

    if limit == -1:
        for i in range(nc):
            for j in range(1, nr):
                if nans[j, i]:
                    a[j, i] = a[j - 1, i]
    else:
        for i in range(nc):
            for j in range(1, nr):
                if nans[j, i]:
                    if ct == limit:
                        continue
                    a[j, i] = a[j - 1, i]
                    ct += 1
                else:
                    ct = 0
    return a

def bfill_date(ndarray[np.int64_t, ndim=2] a, int limit, ndarray[np.uint8_t, cast=True, ndim=2] nans):
    cdef:
        Py_ssize_t i, j
        int nr = a.shape[0], nc = a.shape[1], ct = 0

    if limit == -1:
        for i in range(nc):
            for j in range(nr - 2, -1, -1):
                if nans[j, i]:
                    a[j, i] = a[j + 1, i]
    else:
        for i in range(nc):
            for j in range(nr - 2, -1, -1):
                if nans[j, i]:
                    if ct == limit:
                        continue
                    a[j, i] = a[j + 1, i]
                    ct += 1
                else:
                    ct = 0
    return a

def streak_int(ndarray[np.int64_t] a):
    cdef:
        Py_ssize_t i
        int n = len(a), count = 1
        ndarray[np.int64_t] b = np.empty(n, dtype='int64')

    b[0] = 1
    for i in range(1, n):
        if a[i] == a[i - 1]:
            b[i] = count + 1
            count += 1
        else:
            count = 1
            b[i] = 1
    return b

def streak_float(ndarray[np.float64_t] a):
    cdef:
        Py_ssize_t i
        int n = len(a), count = 1
        ndarray[np.int64_t] b = np.empty(n, dtype='int64')

    b[0] = 1
    for i in range(1, n):
        if a[i] == a[i - 1]:
            b[i] = count + 1
            count += 1
        else:
            count = 1
            b[i] = 1
    return b

def streak_bool(ndarray[np.uint8_t, cast=True] a):
    cdef:
        Py_ssize_t i
        int n = len(a), count = 1
        ndarray[np.int64_t] b = np.empty(n, dtype='int64')

    b[0] = 1
    for i in range(1, n):
        if a[i] == a[i -1]:
            b[i] = count + 1
            count += 1
        else:
            count = 1
            b[i] = 1
    return b

def streak_str(ndarray[object] a):
    cdef:
        Py_ssize_t i
        int n = len(a), count = 1
        ndarray[np.int64_t] b = np.empty(n, dtype='int64')

    b[0] = 1
    for i in range(1, n):
        if a[i] == a[i -1] and a[i] is not None:
            b[i] = count + 1
            count += 1
        else:
            count = 1
            b[i] = 1
    return b

def streak_date(ndarray[np.int64_t] a):
    cdef:
        Py_ssize_t i
        int n = len(a), count = 1
        ndarray[np.int64_t] b = np.empty(n, dtype='int64')
        np.int64_t nat = np.datetime64('nat').astype('int64')

    b[0] = 1
    for i in range(1, n):
        if a[i] == a[i - 1] and a[i] != nat:
            b[i] = count + 1
            count += 1
        else:
            count = 1
            b[i] = 1
    return b

def streak_value_int(ndarray[np.int64_t] a, long value):
    cdef:
        Py_ssize_t i
        int n = len(a), count = 0
        ndarray[np.int64_t] b = np.empty(n, dtype='int64')

    for i in range(n):
        if a[i] == value:
            b[i] = count + 1
            count += 1
        else:
            count = 0
            b[i] = 0
    return b

def streak_value_float(ndarray[np.float64_t] a, float value):
    cdef:
        Py_ssize_t i
        int n = len(a), count = 0
        ndarray[np.int64_t] b = np.empty(n, dtype='int64')

    for i in range(n):
        if a[i] == value:
            b[i] = count + 1
            count += 1
        else:
            count = 0
            b[i] = 0
    return b

def streak_value_bool(ndarray[np.uint8_t, cast=True] a, np.uint8_t value):
    cdef:
        Py_ssize_t i
        int n = len(a), count = 0
        ndarray[np.int64_t] b = np.empty(n, dtype='int64')

    for i in range(n):
        if a[i] == value:
            b[i] = count + 1
            count += 1
        else:
            count = 0
            b[i] = 0
    return b

def streak_value_str(ndarray[object] a, str value):
    cdef:
        Py_ssize_t i
        int n = len(a), count = 0
        ndarray[np.int64_t] b = np.empty(n, dtype='int64')

    for i in range(n):
        if a[i] == value:
            b[i] = count + 1
            count += 1
        else:
            count = 0
            b[i] = 0
    return b

def streak_group_int(ndarray[np.int64_t] a):
    cdef:
        Py_ssize_t i
        int n = len(a), count = 1
        ndarray[np.int64_t] b = np.empty(n, dtype='int64')

    b[0] = 1
    for i in range(1, n):
        if a[i] == a[i -1]:
            b[i] = count
        else:
            count += 1
            b[i] = count
    return b

def streak_group_float(ndarray[np.float64_t] a):
    cdef:
        Py_ssize_t i
        int n = len(a), count = 1
        ndarray[np.int64_t] b = np.empty(n, dtype='int64')

    b[0] = 1
    for i in range(1, n):
        if a[i] == a[i -1]:
            b[i] = count
        else:
            count += 1
            b[i] = count
    return b

def streak_group_bool(ndarray[np.uint8_t, cast=True] a):
    cdef:
        Py_ssize_t i
        int n = len(a), count = 1
        ndarray[np.int64_t] b = np.empty(n, dtype='int64')

    b[0] = 1
    for i in range(1, n):
        if a[i] == a[i -1]:
            b[i] = count
        else:
            count += 1
            b[i] = count
    return b

def streak_group_str(ndarray[object] a):
    cdef:
        Py_ssize_t i
        int n = len(a), count = 1
        ndarray[np.int64_t] b = np.empty(n, dtype='int64')

    b[0] = 1
    for i in range(1, n):
        if a[i] == a[i -1] and a[i] is not None:
            b[i] = count
        else:
            count += 1
            b[i] = count
    return b

def streak_group_date(ndarray[np.int64_t] a):
    cdef:
        Py_ssize_t i
        int n = len(a), count = 1
        ndarray[np.int64_t] b = np.empty(n, dtype='int64')
        np.int64_t nat = np.datetime64('nat').astype('int64')

    b[0] = 1
    for i in range(1, n):
        if a[i] == a[i -1] and a[i] != nat:
            b[i] = count
        else:
            count += 1
            b[i] = count
    return b

def quick_select_int(ndarray[np.int64_t] a, int k):
    cdef:
        Py_ssize_t i
        int n = len(a), ct1 = 0, ct2 = 0
        long r = np.random.randint(n), pivot = a[r]
        ndarray[np.int64_t] a1 = np.empty(n, dtype='int64')
        ndarray[np.int64_t] a2 = np.empty(n, dtype='int64')

    for i in range(len(a)):
        if a[i] < pivot:
            a1[ct1] = a[i]
            ct1 += 1
        elif a[i] > pivot:
            a2[ct2] = a[i]
            ct2 += 1

    if k <= ct1:
        return quick_select_int(a1[:ct1], k)
    elif k > len(a) - ct2:
        return quick_select_int(a2[:ct2], k - (len(a) - ct2))
    return pivot

def quick_select_float(ndarray[np.float64_t] a, int k):
    cdef:
        Py_ssize_t i
        int n = len(a), ct1 = 0, ct2 = 0, r = np.random.randint(n)
        np.float64_t pivot = a[r]
        ndarray[np.float64_t] a1 = np.empty(n, dtype='float64'), a2 = np.empty(n, dtype='float64')

    for i in range(len(a)):
        if a[i] < pivot:
            a1[ct1] = a[i]
            ct1 += 1
        elif a[i] > pivot:
            a2[ct2] = a[i]
            ct2 += 1

    if k <= ct1:
        return quick_select_float(a1[:ct1], k)
    elif k > len(a) - ct2:
        return quick_select_float(a2[:ct2], k - (len(a) - ct2))
    return pivot

def quick_select_str(ndarray[object] a, int k):
    cdef:
        Py_ssize_t i
        int n = len(a), ct1 = 0, ct2 = 0, r = np.random.randint(n)
        str pivot = a[r]
        ndarray[object] a1 = np.empty(n, dtype='O'), a2 = np.empty(n, dtype='O')

    for i in range(len(a)):
        if a[i] < pivot:
            a1[ct1] = a[i]
            ct1 += 1
        elif a[i] > pivot:
            a2[ct2] = a[i]
            ct2 += 1

    if k <= ct1:
        return quick_select_str(a1[:ct1], k)
    elif k > len(a) - ct2:
        return quick_select_str(a2[:ct2], k - (len(a) - ct2))
    return pivot

def nlargest_int(ndarray[np.int64_t] a, n):
    cdef:
        Py_ssize_t i, j, k
        int prev, prev2, prev_arg, prev_arg2, nr = len(a), n1 = n - 1
        ndarray[np.int64_t] topn_arg = np.argsort(-a[:n], kind='mergesort'), topn = a[topn_arg]
        list ties = []

    for i in range(n, nr):
        if a[i] < topn[n1]:
            continue
        if a[i] == topn[n1]:
            ties.append(i)
            continue

        for j in range(n):
            if a[i] > topn[j]:
                prev = topn[j]
                prev_arg = topn_arg[j]

                topn[j] = a[i]
                topn_arg[j] = i
                for k in range(j + 1, n):
                    prev2 = topn[k]
                    prev2_arg = topn_arg[k]

                    topn[k] = prev
                    topn_arg[k] = prev_arg
                    prev = prev2
                    prev_arg = prev2_arg
                break

        if topn[n1] == prev:
            ties = [prev_arg] + ties
        else:
            ties = []

    return topn_arg, ties

# saves a bit of time when doing just first
# def nlargest_int_first(ndarray[np.int64_t] a, n):
#         int i, j, k, prev, prev2
#         int prev_arg, prev_arg2
#         int nr = len(a)
#         ndarray[np.int64_t] topn_arg = np.argsort(-a[:n], kind='mergesort')
#         ndarray[np.int64_t] topn = a[topn_arg]
#         int n1 = n - 1
#
#     for i in range(n, nr):
#         if a[i] <= topn[n1]:
#             continue
#
#         for j in range(n):
#             if a[i] > topn[j]:
#                 prev = topn[j]
#                 prev_arg = topn_arg[j]
#
#                 topn[j] = a[i]
#                 topn_arg[j] = i
#                 for k in range(j + 1, n):
#                     prev2 = topn[k]
#                     prev2_arg = topn_arg[k]
#
#                     topn[k] = prev
#                     topn_arg[k] = prev_arg
#                     prev = prev2
#                     prev_arg = prev2_arg
#                 break
#
#     return topn_arg

def nlargest_float(ndarray[np.float64_t] a, n):
    cdef:
        Py_ssize_t i, j, k
        int init_count = 0, prev_arg, prev_arg2, nr = len(a), n1 = n - 1
        float prev, prev2
        ndarray[np.int64_t] topn_arg = np.empty(n, dtype='int64')
        ndarray[np.float64_t] topn = np.empty(n, dtype='float64')
        list ties = [], none_idx = []

    for i in range(nr):
        if isnan(a[i]):
            none_idx.append(i)
            continue
        topn[init_count] = a[i]
        topn_arg[init_count] = i
        init_count += 1
        if init_count == n:
            first_row = i + 1
            break

    if init_count < n:
        temp_arg = np.argsort(-topn[:init_count], kind='mergesort')
        temp_arg = topn_arg[temp_arg]
        if none_idx:
            return np.append(temp_arg, none_idx)[:n], []
        else:
            return temp_arg, []
    else:
        temp_arg = np.argsort(-topn, kind='mergesort')
        topn = topn[temp_arg]
        topn_arg = topn_arg[temp_arg]

    for i in range(first_row, nr):
        if a[i] < topn[n1] or isnan(a[i]):
            continue
        if a[i] == topn[n1]:
            ties.append(i)
            continue

        for j in range(n):
            if a[i] > topn[j]:
                prev = topn[j]
                prev_arg = topn_arg[j]

                topn[j] = a[i]
                topn_arg[j] = i
                for k in range(j + 1, n):
                    prev2 = topn[k]
                    prev2_arg = topn_arg[k]

                    topn[k] = prev
                    topn_arg[k] = prev_arg
                    prev = prev2
                    prev_arg = prev2_arg
                break

        if topn[n1] == prev:
            ties = [prev_arg] + ties
        else:
            ties = []

    return topn_arg, ties

def nlargest_str(ndarray[object] a, n):
    cdef:
        Py_ssize_t i, j, k
        int first_row, init_count = 0, prev_arg, prev_arg2, nr = len(a), n1 = n - 1
        str prev, prev2
        ndarray[np.int64_t] topn_arg = np.empty(n, dtype='int64'), temp_arg
        ndarray[object] topn = np.empty(n, dtype='O')
        list ties = [], none_idx = []

    for i in range(nr):
        if a[i] is None:
            none_idx.append(i)
            continue
        topn[init_count] = a[i]
        topn_arg[init_count] = i
        init_count += 1
        if init_count == n:
            first_row = i + 1
            break

    if init_count < n:
        temp_arg = (init_count - 1 - np.argsort(topn[:init_count][::-1], kind='mergesort'))[::-1]
        temp_arg = topn_arg[temp_arg]
        if none_idx:
            return np.append(temp_arg, none_idx)[:n], []
        else:
            return temp_arg, []
    else:
        temp_arg = (n - 1 - np.argsort(topn[::-1], kind='mergesort'))[::-1]
        topn = topn[temp_arg]
        topn_arg = topn_arg[temp_arg]

    for i in range(first_row, nr):
        if a[i] is None or a[i] < topn[n1]:
            continue
        if a[i] == topn[n1]:
            ties.append(i)
            continue

        for j in range(n):
            if a[i] > topn[j]:
                prev = topn[j]
                prev_arg = topn_arg[j]

                topn[j] = a[i]
                topn_arg[j] = i
                for k in range(j + 1, n):
                    prev2 = topn[k]
                    prev2_arg = topn_arg[k]

                    topn[k] = prev
                    topn_arg[k] = prev_arg
                    prev = prev2
                    prev_arg = prev2_arg
                break

        if topn[n1] == prev:
            ties = [prev_arg] + ties
        else:
            ties = []

    return topn_arg, ties

def nlargest_bool(ndarray[np.uint8_t, cast=True] a, n):
    cdef:
        Py_ssize_t i, j, k
        int prev, prev2, prev_arg, prev_arg2, nr = len(a), n1 = n - 1
        ndarray[np.int64_t] topn_arg = np.argsort(~a[:n], kind='mergesort')
        ndarray[np.uint8_t, cast=True] topn = a[topn_arg]
        list ties = []

    for i in range(n, nr):
        if a[i] < topn[n1]:
            continue
        if a[i] == topn[n1]:
            ties.append(i)
            continue

        for j in range(n):
            if a[i] > topn[j]:
                prev = topn[j]
                prev_arg = topn_arg[j]

                topn[j] = a[i]
                topn_arg[j] = i
                for k in range(j + 1, n):
                    prev2 = topn[k]
                    prev2_arg = topn_arg[k]

                    topn[k] = prev
                    topn_arg[k] = prev_arg
                    prev = prev2
                    prev_arg = prev2_arg
                break

        if topn[n1] == prev:
            ties = [prev_arg] + ties
        else:
            ties = []

    return topn_arg, ties

def nsmallest_int(ndarray[np.int64_t] a, n):
    cdef:
        Py_ssize_t i, j, k
        int prev, prev2, prev_arg, prev_arg2, nr = len(a), n1 = n - 1
        ndarray[np.int64_t] topn_arg = np.argsort(a[:n], kind='mergesort'), topn = a[topn_arg]
        list ties = []

    for i in range(n, nr):
        if a[i] > topn[n1]:
            continue
        if a[i] == topn[n1]:
            ties.append(i)
            continue

        for j in range(n):
            if a[i] < topn[j]:
                prev = topn[j]
                prev_arg = topn_arg[j]

                topn[j] = a[i]
                topn_arg[j] = i
                for k in range(j + 1, n):
                    prev2 = topn[k]
                    prev2_arg = topn_arg[k]

                    topn[k] = prev
                    topn_arg[k] = prev_arg
                    prev = prev2
                    prev_arg = prev2_arg
                break

        if topn[n1] == prev:
            ties.append(prev_arg)
        else:
            ties = []

    return topn_arg, ties

def nsmallest_float(ndarray[np.float64_t] a, n):
    cdef:
        Py_ssize_t i, j, k
        int init_count = 0, prev_arg, prev_arg2, nr = len(a), n1 = n - 1
        float prev, prev2
        ndarray[np.int64_t] topn_arg = np.empty(n, dtype='int64')
        ndarray[np.float64_t] topn = np.empty(n, dtype='float64')
        list ties = [], none_idx = []

    for i in range(nr):
        if isnan(a[i]):
            none_idx.append(i)
            continue
        topn[init_count] = a[i]
        topn_arg[init_count] = i
        init_count += 1
        if init_count == n:
            first_row = i + 1
            break

    if init_count < n:
        temp_arg = np.argsort(topn[:init_count], kind='mergesort')
        temp_arg = topn_arg[temp_arg]
        if none_idx:
            return np.append(temp_arg, none_idx)[:n], []
        else:
            return temp_arg, []
    else:
        temp_arg = np.argsort(topn, kind='mergesort')
        topn = topn[temp_arg]
        topn_arg = topn_arg[temp_arg]

    for i in range(first_row, nr):
        if a[i] > topn[n1] or isnan(a[i]):
            continue
        if a[i] == topn[n1]:
            ties.append(i)
            continue

        for j in range(n):
            if a[i] < topn[j]:
                prev = topn[j]
                prev_arg = topn_arg[j]

                topn[j] = a[i]
                topn_arg[j] = i
                for k in range(j + 1, n):
                    prev2 = topn[k]
                    prev2_arg = topn_arg[k]

                    topn[k] = prev
                    topn_arg[k] = prev_arg
                    prev = prev2
                    prev_arg = prev2_arg
                break

        if topn[n1] == prev:
            ties = [prev_arg] + ties
        else:
            ties = []

    return topn_arg, ties

def nsmallest_str(ndarray[object] a, n):
    cdef:
        Py_ssize_t i, j, k
        int first_row, init_count = 0, prev_arg, prev_arg2, nr = len(a), n1 = n - 1
        str prev, prev2
        ndarray[np.int64_t] topn_arg = np.empty(n, dtype='int64'), temp_arg
        ndarray[object] topn = np.empty(n, dtype='O')
        list ties = [], none_idx = []

    for i in range(nr):
        if a[i] is None:
            none_idx.append(i)
            continue
        topn[init_count] = a[i]
        topn_arg[init_count] = i
        init_count += 1
        if init_count == n:
            first_row = i + 1
            break

    if init_count < n:
        temp_arg = np.argsort(topn[:init_count], kind='mergesort')
        temp_arg = topn_arg[temp_arg]
        if none_idx:
            return np.append(temp_arg, none_idx)[:n], []
        else:
            return temp_arg, []
    else:
        temp_arg = np.argsort(topn[:init_count], kind='mergesort')
        topn = topn[temp_arg]
        topn_arg = topn_arg[temp_arg]

    for i in range(first_row, nr):
        if a[i] is None or a[i] > topn[n1]:
            continue
        if a[i] == topn[n1]:
            ties.append(i)
            continue

        for j in range(n):
            if a[i] < topn[j]:
                prev = topn[j]
                prev_arg = topn_arg[j]

                topn[j] = a[i]
                topn_arg[j] = i
                for k in range(j + 1, n):
                    prev2 = topn[k]
                    prev2_arg = topn_arg[k]

                    topn[k] = prev
                    topn_arg[k] = prev_arg
                    prev = prev2
                    prev_arg = prev2_arg
                break

        if topn[n1] == prev:
            ties = [prev_arg] + ties
        else:
            ties = []

    return topn_arg, ties

def nsmallest_bool(ndarray[np.uint8_t, cast=True] a, n):
    cdef:
        Py_ssize_t i, j, k
        int prev, prev2, prev_arg, prev_arg2, nr = len(a), n1 = n - 1
        ndarray[np.int64_t] topn_arg = np.argsort(a[:n], kind='mergesort')
        ndarray[np.uint8_t, cast=True] topn = a[topn_arg]
        list ties = []

    for i in range(n, nr):
        if a[i] > topn[n1]:
            continue
        if a[i] == topn[n1]:
            ties.append(i)
            continue

        for j in range(n):
            if a[i] < topn[j]:
                prev = topn[j]
                prev_arg = topn_arg[j]

                topn[j] = a[i]
                topn_arg[j] = i
                for k in range(j + 1, n):
                    prev2 = topn[k]
                    prev2_arg = topn_arg[k]

                    topn[k] = prev
                    topn_arg[k] = prev_arg
                    prev = prev2
                    prev_arg = prev2_arg
                break

        if topn[n1] == prev:
            ties = [prev_arg] + ties
        else:
            ties = []

    return topn_arg, ties

def quick_select_int2(ndarray[np.int64_t] arr, int n, int k):
    # Credit: Ryan Tibshirani - http://www.stat.cmu.edu/~ryantibs/median/
    cdef:
        long i, ir, j, l, mid, a, temp

    l = 0
    ir = n - 1
    while True:
        if ir <= l + 1:
            if (ir == l + 1) and (arr[ir] < arr[l]):
                temp = arr[l]
                arr[l] = arr[ir]
                arr[ir] = temp
            return arr[k]
        else:
            mid = (l + ir) // 2

            temp = arr[mid]
            arr[mid] = arr[l + 1]
            arr[l + 1] = temp

            if arr[l] > arr[ir]:
                temp = arr[l]
                arr[l] = arr[ir]
                arr[ir] = temp

            if arr[l + 1] > arr[ir]:
                temp = arr[l + 1]
                arr[l + 1] = arr[ir]
                arr[ir] = temp

            if arr[l] > arr[l + 1]:
                temp = arr[l]
                arr[l] = arr[l + 1]
                arr[l + 1] = temp

            i = l+1
            j = ir

            a = arr[l+1]
            while True:
                i += 1
                while arr[i] < a:
                    i += 1

                j -= 1
                while arr[j] > a:
                    j -= 1

                if j < i:
                    break

                temp = arr[i]
                arr[i] = arr[j]
                arr[j] = temp

            arr[l + 1] = arr[j]
            arr[j] = a
            if j >= k:
                ir = j - 1
            if j <= k:
                l = i

def quick_select_float2(ndarray[np.float64_t] arr, int n, int k):
    # Credit: Ryan Tibshirani - http://www.stat.cmu.edu/~ryantibs/median/
    cdef:
        long i, ir, j, l, mid
        np.float64_t a, temp

    l = 0
    ir = n - 1
    while True:
        if ir <= l + 1:
            if (ir == l + 1) and (arr[ir] < arr[l]):
                temp = arr[l]
                arr[l] = arr[ir]
                arr[ir] = temp
            return arr[k]
        else:
            mid = (l + ir) // 2

            temp = arr[mid]
            arr[mid] = arr[l + 1]
            arr[l + 1] = temp

            if arr[l] > arr[ir]:
                temp = arr[l]
                arr[l] = arr[ir]
                arr[ir] = temp

            if arr[l + 1] > arr[ir]:
                temp = arr[l + 1]
                arr[l + 1] = arr[ir]
                arr[ir] = temp

            if arr[l] > arr[l + 1]:
                temp = arr[l]
                arr[l] = arr[l + 1]
                arr[l + 1] = temp

            i = l+1
            j = ir

            a = arr[l+1]
            while True:
                i += 1
                while arr[i] < a:
                    i += 1

                j -= 1
                while arr[j] > a:
                    j -= 1

                if j < i:
                    break

                temp = arr[i]
                arr[i] = arr[j]
                arr[j] = temp

            arr[l + 1] = arr[j]
            arr[j] = a
            if j >= k:
                ir = j - 1
            if j <= k:
                l = i

def copy(ndarray[np.float64_t] a):
    cdef:
        Py_ssize_t n = len(a), s = sizeof(np.float64_t) * n
        np.float64_t *arr = <np.float64_t*> a.data
        np.float64_t *arr2 = <np.float64_t *> malloc(s)

    memcpy(arr2, arr, s)
    try:
        return np.asarray(<np.float64_t[:n]> arr2)
    finally:
        free(arr2)