$(document).ready( function() {
    var grouped_by_project = 0;
    var all_metagenomes_table_id = 0;
    $("#grouping_link").live('click', function () {
	switch_project_grouping();
      });
    $("#ungrouping_link").live('click', function () {
	switch_project_grouping();
      });
    function switch_project_grouping(){
      if (grouped_by_project) {
	clear_pivot(all_metagenomes_table_id, "2", "0|1|3|4|5|6");
	$("#colname_"+all_metagenomes_table_id+"_col_2").html("id");
	$("#ungrouping_link").hide();
	$("#grouping_link").show();
	show_column(all_metagenomes_table_id, "15");
	$("#metagenome_counts").show();
	grouped_by_project = 0;
	table_reset_filters(all_metagenomes_table_id);
      } else {
	clear_pivot(all_metagenomes_table_id, "2", "0|1|3|4|5|6|7");
	pivot_plus(all_metagenomes_table_id, "2", "0|1|3|4|5|6|7", "hash|num|hash|hash|hash|hash|hash", null, ", ");
	$("#colname_"+all_metagenomes_table_id+"_col_2").html("# of jobs");
	show_column(all_metagenomes_table_id, "1");
	hide_column(all_metagenomes_table_id, "15");
	$("#grouping_link").hide();
	$("#ungrouping_link").show();
	$("#metagenome_counts").hide();
	grouped_by_project = 1;
      }
    }
});
