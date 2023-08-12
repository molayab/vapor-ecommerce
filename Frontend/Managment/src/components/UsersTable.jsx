import { Table, TableBody, TableCell, TableHead, TableRow, TableHeaderCell, Flex, Button, TextInput } from '@tremor/react'

function UsersTable({ users }) {
    return (
        <div className="mt-10">
            <Table>
                <TableHead>
                    <TableRow>
                    <TableHeaderCell>Nombre</TableHeaderCell>
                    <TableHeaderCell>ID</TableHeaderCell>
                    <TableHeaderCell>Roles</TableHeaderCell>
                    <TableHeaderCell>Telefono</TableHeaderCell>
                    </TableRow>
                    
                </TableHead>
                <TableBody>
                    {users.map((user) => (
                        <TableRow key={user.id}>
                            <TableCell>{user.name}</TableCell>
                            <TableCell>{user.id}</TableCell>
                            <TableCell>{user.rolesString}</TableCell>
                            <TableCell>{user.isActive}</TableCell>
                        </TableRow>
                    ))}
                    
                </TableBody>
            </Table>
        </div>
    )
}

export default UsersTable