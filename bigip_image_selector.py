#!/usr/bin/env python3

import sys
import json
import urllib.request
import difflib

ALLOWED_TMOS_TYPES = ['all', 'ltm']
PUBLIC_REGIONS = ['us-south', 'us-east', 'eu-gb',
                  'eu-de', 'jp-tok', 'jp-osa', 'au-syd', 'ca-tor', 'br-sao']


def get_public_images(region):
    if not region:
        region = 'us-south'
    catalog_url = "https://f5-adc-%s.s3.%s.cloud-object-storage.appdomain.cloud/f5-image-catalog.json" % (
        region, region)
    try:
        response = urllib.request.urlopen(catalog_url)
        return json.load(response)
    except Exception as ex:
        sys.stderr.write(
            'Can not fetch F5 image catalog at %s: %s' % (catalog_url, ex))
        sys.exit(1)


def longest_substr(type, catalog_image_name, version_prefix):
    if catalog_image_name.find(type) < 0:
        return 0
    if catalog_image_name.find(version_prefix) < 0:
        return 0
    seqMatch = difflib.SequenceMatcher(
        None, catalog_image_name, version_prefix)
    match = seqMatch.find_longest_match(
        0, len(catalog_image_name), 0, len(version_prefix))
    return match.size


def get_image(region, type, version):
    image_catalog = get_public_images(region)
    max_match = 0
    image_url = None
    image_name = None
    image_id = None
    for image in image_catalog[region]:
        match_length = longest_substr(
            type, image['image_name'], version)
        if match_length > 0 and match_length >= max_match:
            max_match = match_length
            image_url = image['image_sql_url']
            image_name = image['image_name']
            image_id = image['image_id']
    return (image_url, image_name, image_id)


def main():
    jsondata = json.loads(sys.stdin.read())
    if 'type' not in jsondata:
        sys.stderr.write(
            'type, region, verion_prefix inputs require to query public f5 images')
        sys.exit(1)
    if 'region' not in jsondata:
        sys.stderr.write(
            'type, region, verion_prefix inputs require to query public f5 images')
        sys.exit(1)
    if 'version_prefix' not in jsondata:
        sys.stderr.write(
            'type, region, verion_prefix inputs require to query public f5 images')
        sys.exit(1)
    tmos_type = jsondata['type'].lower()
    if tmos_type not in ALLOWED_TMOS_TYPES:
        sys.stderr.write('TMOS type must be in: %s' %
                         ALLOWED_TMOS_TYPES)
        sys.exit(1)
    tmos_version_match = jsondata['version_prefix'].lower().replace('.', '-')
    region = jsondata['region'].lower()
    if region not in PUBLIC_REGIONS:
        sys.stderr.write(
            'public f5 images are not supported in region: %s. Use a custom VPC image.' % region)
        sys.exit(1)
    (image_url, image_name, image_id) = get_image(region, tmos_type, tmos_version_match)
    if not image_url:
        sys.stderr.write(
            'No image in the public image catalog matched version %s' % tmos_version_match)
        sys.exit(1)
    jsondata['image_sql_url'] = image_url
    jsondata['image_name'] = image_name
    jsondata['image_id'] = image_id
    sys.stdout.write(json.dumps(jsondata))


if __name__ == '__main__':
    main()
