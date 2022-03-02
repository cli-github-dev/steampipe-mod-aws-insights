dashboard "aws_sqs_queue_encryption_report" {

  title = "AWS SQS Queue Encryption Report"

  tags = merge(local.sqs_common_tags, {
    type     = "Report"
    category = "Encryption"
  })

  container {

    card {
      sql   = query.aws_sqs_queue_count.sql
      width = 2
    }

    card {
      sql   = query.aws_sqs_queue_unencrypted_count.sql
      width = 2
    }

  }

  table {

    column "Account ID" {
      display = "none"
    }

    sql = query.aws_sqs_queue_encryption_table.sql
  }

}
query "aws_sqs_queue_encryption_table" {
  sql = <<-EOQ
    select
      r.title as "Queue",
      case when kms_master_key_id is not null then 'Enabled' else null end as "Encryption",
      r.kms_master_key_id as "KMS Key ID",
      a.title as "Account",
      r.account_id as "Account ID",
      r.region as "Region"
    from
      aws_sqs_queue as r,
      aws_account as a
    where
      r.account_id = a.account_id;
  EOQ
}
