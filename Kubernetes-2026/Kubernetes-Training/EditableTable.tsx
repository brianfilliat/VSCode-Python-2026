import { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Plus, Trash2, Edit2, Save, X } from "lucide-react";
import { trpc } from "@/lib/trpc";
import { toast } from "sonner";

interface EditableTableProps {
  table: {
    id: number;
    title: string;
    tableName: string;
    columns?: string | null;
    rows?: any[];
  };
  sectionTitle: string;
  isEditable: boolean;
}

export default function EditableTable({ table, sectionTitle, isEditable }: EditableTableProps) {
  const [editingRowId, setEditingRowId] = useState<number | null>(null);
  const [editingData, setEditingData] = useState<Record<string, any>>({});
  const [isAddingRow, setIsAddingRow] = useState(false);
  const [newRowData, setNewRowData] = useState<Record<string, any>>({});

  const utils = trpc.useUtils();

  const columns = table.columns ? JSON.parse(table.columns) : [];
  const rows = table.rows || [];

  const updateRowMutation = trpc.training.updateTableRow.useMutation({
    onSuccess: () => {
      toast.success("Row updated");
      setEditingRowId(null);
      utils.training.getTopicBySlug.invalidate();
    },
    onError: () => {
      toast.error("Failed to update row");
    },
  });

  const addRowMutation = trpc.training.addTableRow.useMutation({
    onSuccess: () => {
      toast.success("Row added");
      setIsAddingRow(false);
      setNewRowData({});
      utils.training.getTopicBySlug.invalidate();
    },
    onError: () => {
      toast.error("Failed to add row");
    },
  });

  const deleteRowMutation = trpc.training.deleteTableRow.useMutation({
    onSuccess: () => {
      toast.success("Row deleted");
      utils.training.getTopicBySlug.invalidate();
    },
    onError: () => {
      toast.error("Failed to delete row");
    },
  });

  const handleEditRow = (row: any) => {
    setEditingRowId(row.id);
    setEditingData(row.rowData || {});
  };

  const handleSaveRow = async () => {
    if (editingRowId) {
      await updateRowMutation.mutateAsync({
        rowId: editingRowId,
        rowData: editingData,
      });
    }
  };

  const handleAddRow = async () => {
    await addRowMutation.mutateAsync({
      tableId: table.id,
      rowData: newRowData,
      order: rows.length,
    });
  };

  const handleDeleteRow = async (rowId: number) => {
    if (confirm("Are you sure you want to delete this row?")) {
      await deleteRowMutation.mutateAsync({ rowId });
    }
  };

  return (
    <Card className="editable-table-card">
      <CardHeader>
        <div className="table-header">
          <div>
            <CardTitle className="table-title">{table.title}</CardTitle>
            <p className="table-section">{sectionTitle}</p>
          </div>
          {isEditable && (
            <Button
              size="sm"
              onClick={() => setIsAddingRow(!isAddingRow)}
              className="add-row-button"
            >
              <Plus className="w-4 h-4 mr-2" />
              Add Row
            </Button>
          )}
        </div>
      </CardHeader>

      <CardContent className="table-content">
        <div className="table-wrapper">
          <Table>
            <TableHeader>
              <TableRow>
                {columns.map((col: string) => (
                  <TableHead key={col} className="table-header-cell">
                    {col}
                  </TableHead>
                ))}
                {isEditable && <TableHead className="table-actions-header">Actions</TableHead>}
              </TableRow>
            </TableHeader>
            <TableBody>
              {/* Add Row Form */}
              {isAddingRow && (
                <TableRow className="add-row-form">
                  {columns.map((col: string) => (
                    <TableCell key={col}>
                      <Input
                        placeholder={col}
                        value={newRowData[col] || ""}
                        onChange={(e) =>
                          setNewRowData({ ...newRowData, [col]: e.target.value })
                        }
                        className="table-input"
                      />
                    </TableCell>
                  ))}
                  <TableCell className="table-actions">
                    <Button
                      size="sm"
                      onClick={handleAddRow}
                      disabled={addRowMutation.isPending}
                      className="save-button"
                    >
                      <Save className="w-4 h-4" />
                    </Button>
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => setIsAddingRow(false)}
                    >
                      <X className="w-4 h-4" />
                    </Button>
                  </TableCell>
                </TableRow>
              )}

              {/* Data Rows */}
              {rows.map((row) => (
                <TableRow key={row.id} className={editingRowId === row.id ? "editing" : ""}>
                  {columns.map((col: string) => (
                    <TableCell key={col} className="table-cell">
                      {editingRowId === row.id ? (
                        <Input
                          value={editingData[col] || ""}
                          onChange={(e) =>
                            setEditingData({ ...editingData, [col]: e.target.value })
                          }
                          className="table-input"
                        />
                      ) : (
                        <span>{row.rowData?.[col] || "-"}</span>
                      )}
                    </TableCell>
                  ))}
                  {isEditable && (
                    <TableCell className="table-actions">
                      {editingRowId === row.id ? (
                        <>
                          <Button
                            size="sm"
                            onClick={handleSaveRow}
                            disabled={updateRowMutation.isPending}
                            className="save-button"
                          >
                            <Save className="w-4 h-4" />
                          </Button>
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => setEditingRowId(null)}
                          >
                            <X className="w-4 h-4" />
                          </Button>
                        </>
                      ) : (
                        <>
                          <Button
                            size="sm"
                            variant="ghost"
                            onClick={() => handleEditRow(row)}
                          >
                            <Edit2 className="w-4 h-4" />
                          </Button>
                          <Button
                            size="sm"
                            variant="ghost"
                            onClick={() => handleDeleteRow(row.id)}
                            className="delete-button"
                          >
                            <Trash2 className="w-4 h-4" />
                          </Button>
                        </>
                      )}
                    </TableCell>
                  )}
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      </CardContent>
    </Card>
  );
}
