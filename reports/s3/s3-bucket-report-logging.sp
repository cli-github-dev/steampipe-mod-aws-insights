query "aws_s3_bucket_logging_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Logging Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as style
    from
      aws_s3_bucket
    where
      logging -> 'TargetBucket' is null
  EOQ
}


report "aws_s3_bucket_logging_report" {

  title = "AWS S3 Bucket Logging Report"

  container {

    counter {
      sql = query.aws_s3_bucket_logging_disabled_count.sql
      width = 2
    }

  }

  table {
    sql = <<-EOQ
      select
        name as "Bucket",
        case when logging -> 'TargetBucket' is not null then 'Enabled' else null end as "Logging",
        (logging ->> 'TargetBucket') || (logging ->> 'TargetPrefix') as "Target",
        logging -> 'TargetGrants' as "Grants",
        account_id as "Account",
        region as "Region",
        arn as "ARN"
      from
        aws_s3_bucket
    EOQ
  }

}
