dashboard "aws_rds_db_instance_public_access_report" {

  title = "AWS RDS DB Instance Public Access Report"

  tags = merge(local.rds_common_tags, {
    type     = "Report"
    category = "Public Access"
  })

  container {

    card {
      sql   = query.aws_rds_db_instance_count.sql
      width = 2
    }

    card {
      sql = query.aws_rds_db_instance_public_count.sql
      width = 2
    }
  }

  table {

    column "Account ID" {
      display = "none"
    }

    column "ARN" {
      display = "none"
    }

    column "DB Instance Identifier" {
      href = "/aws_insights.dashboard.aws_rds_db_instance_detail?input.db_instance_arnn={{.ARN | @uri}}"
    }

    sql = query.aws_rds_db_instance_public_access_table.sql
  }

}

query "aws_rds_db_instance_public_access_table" {
  sql = <<-EOQ
    select
      i.db_instance_identifier as "DB Instance Identifier",
      case
        when i.publicly_accessible then 'Public' else 'Private' end as "Public/Private",
      i.status as "Status",
      a.title as "Account",
      i.account_id as "Account ID",
      i.region as "Region",
      i.arn as "ARN"
    from
      aws_rds_db_instance as i,
      aws_account as a
    where
      i.account_id = a.account_id
    order by
      i.db_instance_identifier;
  EOQ
}
