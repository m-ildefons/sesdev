import pytest

from seslib.deployment import Deployment
from seslib.zypper import ZypperPackage


def test_list_pacakages():
    empty_dep_list = Deployment._parse_zypper_s11_packages('')
    assert empty_dep_list == []
    dep_list = Deployment._parse_zypper_s11_packages(
        "Loading repository data...\n"
        "Reading installed packages...\n"
        "S   Repository              Name                                        Version                                  Arch\n"  # noqa: E501
        "                                                                                                                     \n"  # noqa: E501
        "i   @System                 libyui11                                    3.9.3-lp152.1.3                          x86_64\n"  # noqa: E501
        "i   @System                 libisccfg160                                9.11.2-lp152.13.6                        x86_64\n"  # noqa: E501
        "i   @System                 libisccc160                                 9.11.2-lp152.13.6                        x86_64\n"  # noqa: E501
    )
    assert [_.name for _ in dep_list] == ['libyui11',
                                          'libisccfg160',
                                          'libisccc160']
