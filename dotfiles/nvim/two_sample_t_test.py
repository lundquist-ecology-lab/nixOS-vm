"""
Two-Sample T-Test Implementation in Python

This script demonstrates how to perform a two-sample t-test to compare
the means of two independent groups.
"""

import numpy as np
from scipy import stats


def two_sample_t_test_manual(sample1, sample2, equal_var=True):
    """
    Manually calculate a two-sample t-test.

    Parameters:
    -----------
    sample1 : array-like
        First sample data
    sample2 : array-like
        Second sample data
    equal_var : bool
        If True, perform standard t-test assuming equal variances (pooled variance)
        If False, perform Welch's t-test (does not assume equal variances)

    Returns:
    --------
    t_statistic : float
        The calculated t-statistic
    p_value : float
        The two-tailed p-value
    """
    n1 = len(sample1)
    n2 = len(sample2)

    mean1 = np.mean(sample1)
    mean2 = np.mean(sample2)

    var1 = np.var(sample1, ddof=1)  # ddof=1 for sample variance
    var2 = np.var(sample2, ddof=1)

    if equal_var:
        # Pooled standard deviation
        pooled_var = ((n1 - 1) * var1 + (n2 - 1) * var2) / (n1 + n2 - 2)
        se = np.sqrt(pooled_var * (1/n1 + 1/n2))
        df = n1 + n2 - 2
    else:
        # Welch's t-test (unequal variances)
        se = np.sqrt(var1/n1 + var2/n2)
        # Welch-Satterthwaite degrees of freedom
        df = (var1/n1 + var2/n2)**2 / ((var1/n1)**2/(n1-1) + (var2/n2)**2/(n2-1))

    # Calculate t-statistic
    t_stat = (mean1 - mean2) / se

    # Calculate two-tailed p-value
    p_value = 2 * (1 - stats.t.cdf(abs(t_stat), df))

    return t_stat, p_value, df


def main():
    # Example 1: Using scipy (recommended for most cases)
    print("=" * 60)
    print("TWO-SAMPLE T-TEST EXAMPLES")
    print("=" * 60)

    # Sample data: comparing test scores between two groups
    group1 = np.array([85, 90, 78, 92, 88, 76, 95, 89, 84, 91])
    group2 = np.array([70, 75, 68, 80, 72, 74, 78, 71, 69, 76])

    print("\nGroup 1 scores:", group1)
    print("Group 2 scores:", group2)
    print(f"\nGroup 1 mean: {np.mean(group1):.2f}, std: {np.std(group1, ddof=1):.2f}")
    print(f"Group 2 mean: {np.mean(group2):.2f}, std: {np.std(group2, ddof=1):.2f}")

    # Method 1: Using scipy (easiest)
    print("\n" + "-" * 60)
    print("METHOD 1: Using scipy.stats.ttest_ind()")
    print("-" * 60)

    # Equal variances assumed (Student's t-test)
    t_stat_scipy, p_value_scipy = stats.ttest_ind(group1, group2)
    print(f"Student's t-test (equal variances):")
    print(f"  t-statistic: {t_stat_scipy:.4f}")
    print(f"  p-value: {p_value_scipy:.4f}")

    # Unequal variances (Welch's t-test)
    t_stat_welch, p_value_welch = stats.ttest_ind(group1, group2, equal_var=False)
    print(f"\nWelch's t-test (unequal variances):")
    print(f"  t-statistic: {t_stat_welch:.4f}")
    print(f"  p-value: {p_value_welch:.4f}")

    # Method 2: Manual calculation
    print("\n" + "-" * 60)
    print("METHOD 2: Manual Calculation")
    print("-" * 60)

    t_stat_manual, p_value_manual, df = two_sample_t_test_manual(group1, group2, equal_var=True)
    print(f"Manual t-test (equal variances):")
    print(f"  t-statistic: {t_stat_manual:.4f}")
    print(f"  p-value: {p_value_manual:.4f}")
    print(f"  degrees of freedom: {df:.0f}")

    # Interpretation
    print("\n" + "=" * 60)
    print("INTERPRETATION")
    print("=" * 60)
    alpha = 0.05
    if p_value_scipy < alpha:
        print(f"p-value ({p_value_scipy:.4f}) < {alpha}")
        print("Result: REJECT the null hypothesis")
        print("Conclusion: There IS a statistically significant difference between the two groups.")
    else:
        print(f"p-value ({p_value_scipy:.4f}) >= {alpha}")
        print("Result: FAIL TO REJECT the null hypothesis")
        print("Conclusion: There is NO statistically significant difference between the two groups.")

    # Effect size (Cohen's d)
    print("\n" + "-" * 60)
    print("EFFECT SIZE (Cohen's d)")
    print("-" * 60)
    pooled_std = np.sqrt(((len(group1)-1)*np.var(group1, ddof=1) +
                          (len(group2)-1)*np.var(group2, ddof=1)) /
                         (len(group1) + len(group2) - 2))
    cohens_d = (np.mean(group1) - np.mean(group2)) / pooled_std
    print(f"Cohen's d: {cohens_d:.4f}")

    if abs(cohens_d) < 0.2:
        effect = "negligible"
    elif abs(cohens_d) < 0.5:
        effect = "small"
    elif abs(cohens_d) < 0.8:
        effect = "medium"
    else:
        effect = "large"
    print(f"Effect size interpretation: {effect}")

    print("\n" + "=" * 60)


if __name__ == "__main__":
    main()
