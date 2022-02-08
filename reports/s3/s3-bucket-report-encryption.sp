query "aws_s3_bucket_unencrypted_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unencrypted' as label,
      case count(*) when 0 then 'ok' else 'alert' end as style
    from
      aws_s3_bucket
    where
      server_side_encryption_configuration is null
  EOQ
}

query "aws_s3_bucket_https_unenforced_count" {
  sql = <<-EOQ
    with ssl_ok as (
      select
        distinct name,
        arn,
        'ok' as status
      from
        aws_s3_bucket,
        jsonb_array_elements(policy_std -> 'Statement') as s,
        jsonb_array_elements_text(s -> 'Principal' -> 'AWS') as p,
        jsonb_array_elements_text(s -> 'Action') as a,
        jsonb_array_elements_text(s -> 'Resource') as r,
        jsonb_array_elements_text(
          s -> 'Condition' -> 'Bool' -> 'aws:securetransport'
        ) as ssl
      where
        p = '*'
        and s ->> 'Effect' = 'Deny'
        and ssl :: bool = false
    )
    select
      count(*) as value,
      'HTTPS Unenforced' as label,
      case count(*) when 0 then 'ok' else 'alert' end as style
    from
      aws_s3_bucket as b
      left join ssl_ok as ssl on ssl.arn != b.arn
  EOQ
}


report "aws_s3_bucket_encryption_report" {

  title = "AWS S3 Bucket Encryption Report"

  container {

    counter {
      sql = query.aws_s3_bucket_unencrypted_count.sql
      width = 2
    }

    counter {
      sql = query.aws_s3_bucket_https_unenforced_count.sql
      width = 2
    }

  }

  table {
    sql = <<-EOQ
      with default_encryption as (
        select
          distinct name,
          arn,
          rules -> 'ApplyServerSideEncryptionByDefault' ->> 'KMSMasterKeyID' as kms_key_master_id,
          rules -> 'ApplyServerSideEncryptionByDefault' ->> 'SSEAlgorithm' as sse_algorithm,
          rules -> 'ApplyServerSideEncryptionByDefault' ->> 'BucketKeyEnabled' as bucket_key_enabled
        from
          aws_s3_bucket,
          jsonb_array_elements(server_side_encryption_configuration -> 'Rules') as rules
      ),
      ssl_ok as (
        select
          distinct name,
          arn,
          'ok' as status
        from
          aws_s3_bucket,
          jsonb_array_elements(policy_std -> 'Statement') as s,
          jsonb_array_elements_text(s -> 'Principal' -> 'AWS') as p,
          jsonb_array_elements_text(s -> 'Action') as a,
          jsonb_array_elements_text(s -> 'Resource') as r,
          jsonb_array_elements_text(
            s -> 'Condition' -> 'Bool' -> 'aws:securetransport'
          ) as ssl
        where
          p = '*'
          and s ->> 'Effect' = 'Deny'
          and ssl :: bool = false
      )
      select
        b.name as "Bucket",
        case when ssl.status = 'ok' then 'Enabled' else null end as "HTTPS Enforced",
        case when b.server_side_encryption_configuration is not null then 'Enabled' else null end as "Default Encryption",
        d.bucket_key_enabled as "Bucket Key Enabled",
        d.sse_algorithm as "SSE Algorithm",
        d.kms_key_master_id as "KMS Key ID",
        b.account_id as "Account",
        b.region as "Region",
        b.arn as "ARN"
      from
        aws_s3_bucket as b
        left join default_encryption as d on b.arn = d.arn
        left join ssl_ok as ssl on b.arn = ssl.arn;
    EOQ
  }

}
