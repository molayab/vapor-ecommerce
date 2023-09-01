import { TrashIcon } from '@heroicons/react/outline'
import { ExclamationCircleIcon, PencilIcon } from '@heroicons/react/solid'
import { Table, TableBody, TableCell, TableHead, TableRow, TableHeaderCell, Callout, Icon } from '@tremor/react'
import { removeUser } from './services/users'
import { useState } from 'react'
import Loader from './Loader'

function UsersTable({ users, setUsers }) {
    const [errors, setErrors] = useState({})
    const [notifications, setNotifications] = useState({})

    const deleteUserAction = async (id) => {
        let response = await removeUser(id)

        if (response.status === 200) {
            setUsers((old) => old.filter((u) => u.id !== id))
        } else {
            setErrors({ title: "Error al eliminar el usuario" })
        }
    }

    if (users === null) {
        return <Loader />
    }

    return (
        <>
        { errors.title &&
            <Callout color="rose" className="mt-2" title="Error" icon={ExclamationCircleIcon}>
                { errors.title }
            </Callout>
        }

        { notifications.title &&
            <Callout color="green" className="mt-2" title="Exito" icon={ExclamationCircleIcon}>
                { notifications.title }
            </Callout>
        }

        <div className="mt-10">
            <Table>
                <TableHead>
                    <TableRow>
                    <TableHeaderCell></TableHeaderCell>
                    <TableHeaderCell>Nombre</TableHeaderCell>
                    <TableHeaderCell>Roles</TableHeaderCell>
                    <TableHeaderCell>Contacto</TableHeaderCell>
                    <TableHeaderCell>Activo?</TableHeaderCell>
                    <TableHeaderCell>Acciones</TableHeaderCell>
                    </TableRow>
                </TableHead>
                <TableBody>
                    {users.map((user) => (
                        <TableRow key={user.id}>
                            <TableCell className='w-20'>
                                <img src={user.gravatar} alt={user.name} className="w-10 h-10 rounded-full" />
                            </TableCell>
                            <TableCell>
                                <strong>{user.name}</strong><br />
                                <small>{user.id}</small>
                            </TableCell>
                            <TableCell>{user.rolesString}</TableCell>
                            <TableCell><a href='mailto:{user.email}'>{user.email}</a></TableCell>
                            <TableCell>{user.isActive ? "SI" : "NO" }</TableCell>
                            <TableCell>
                                <Icon 
                                    onClick={() => { }}
                                    icon={PencilIcon} 
                                    className="text-blue-50 cursor-pointer" />
                                <Icon 
                                    onClick={ (e) => deleteUserAction(user.id)}
                                    icon={TrashIcon} 
                                    className="text-red-500 cursor-pointer" />
                            </TableCell>
                        </TableRow>
                    ))}
                    
                </TableBody>
            </Table>
        </div>
        </>
    )
}

export default UsersTable