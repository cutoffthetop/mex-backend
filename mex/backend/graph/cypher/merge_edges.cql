<# Merge all edges from a single extracted item to all connected merged items.

This statement also prunes all edges originating from a given node that are not
part of the references to be merged during this operation.

Globals:
    merged_labels: List of all merged class labels

Args:
    extracted_label: Label of the extracted item that is the source of all edges being
                     merged in this statement
    ref_labels: Ordered list of merged item labels of the edges being merged

Returns:
    merged: Number of merged edges
    pruned: Number of pruned edges
    edges: List of the merged edge objects
-#>
MATCH (source:<<extracted_label>> {identifier: $identifier})
CALL {
<%- if ref_labels %>
<%- set union = joiner("UNION\n    ") %>
<%- for ref_label in ref_labels %>
<%- set index = loop.index0 %>
    <<union()>>WITH source
    MATCH (target_<<index>> {identifier: $ref_identifiers[<<index>>]})
    MERGE (source)-[edge:<<ref_label>> {position: $ref_positions[<<index>>]}]->(target_<<index>>)
    RETURN edge
<%- endfor %>
<%- else %>
    RETURN null as edge
<%- endif %>
}
WITH source, collect(edge) as edges
CALL {
    WITH source, edges
    MATCH (source)-[outdated_edge]->(:<<merged_labels|join("|")>>)
    WHERE NOT outdated_edge IN edges
    DELETE outdated_edge
    RETURN count(outdated_edge) as pruned
}
RETURN count(edges) as merged, pruned, edges;
