# -*- coding: utf-8 -*-
from pydbm.clustering.interface.computable_clustering_loss import ComputableClusteringLoss
import numpy as np
cimport numpy as np
ctypedef np.float64_t DOUBLE_t


class KMeansLoss(ComputableClusteringLoss):
    '''
    Compute K-Means Loss.

    References:
        - Aljalbout, E., Golkov, V., Siddiqui, Y., Strobel, M., & Cremers, D. (2018). Clustering with deep learning: Taxonomy and new methods. arXiv preprint arXiv:1801.07648.
        - Guo, X., Gao, L., Liu, X., & Yin, J. (2017, June). Improved Deep Embedded Clustering with Local Structure Preservation. In IJCAI (pp. 1753-1759).
        - Xie, J., Girshick, R., & Farhadi, A. (2016, June). Unsupervised deep embedding for clustering analysis. In International conference on machine learning (pp. 478-487).
        - Zhao, J., Mathieu, M., & LeCun, Y. (2016). Energy-based generative adversarial network. arXiv preprint arXiv:1609.03126.

    '''
    
    def __init__(self, weight=0.125):
        '''
        Init.

        Args:
            weight:     Weight of delta and loss.
        '''
        self.__weight = weight
    
    def compute_clustering_loss(
        self, 
        observed_arr, 
        reconstructed_arr, 
        feature_arr,
        delta_arr, 
        q_arr, 
        p_arr, 
    ):
        '''
        Compute clustering loss.

        Args:
            observed_arr:               `np.ndarray` of observed data points.
            reconstructed_arr:          `np.ndarray` of reconstructed data.
            feature_arr:                `np.ndarray` of feature points.
            delta_arr:                  `np.ndarray` of differences between feature points and centroids.
            p_arr:                      `np.ndarray` of result of soft assignment.
            q_arr:                      `np.ndarray` of target distribution.

        Returns:
            Tuple data.
            - `np.ndarray` of delta for the encoder.
            - `np.ndarray` of delta for the decoder.
            - `np.ndarray` of delta for the centroids.
        '''
        cdef np.ndarray label_arr = self.__assign_label(q_arr)
        cdef np.ndarray t_hot_arr = np.zeros((label_arr.shape[0], delta_arr.shape[1]))
        for i in range(label_arr.shape[0]):
            t_hot_arr[i, label_arr[i]] = 1
        t_hot_arr = np.expand_dims(t_hot_arr, axis=2)
        cdef np.ndarray[DOUBLE_t, ndim=3] delta_kmeans_arr = t_hot_arr.astype(np.float) * np.square(delta_arr)
        delta_kmeans_z_arr = np.nanmean(delta_kmeans_arr, axis=1)
        delta_kmeans_z_arr = delta_kmeans_z_arr * self.__weight
        return (delta_kmeans_z_arr, None, None)

    def __assign_label(self, q_arr):
        if q_arr.shape[2] > 1:
            q_arr = np.nanmean(q_arr, axis=2)
        q_arr = q_arr.reshape((q_arr.shape[0], q_arr.shape[1]))
        return q_arr.argmax(axis=1)
